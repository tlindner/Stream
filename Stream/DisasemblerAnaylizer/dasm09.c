/***************************************************************************
 * dasm09 -- Portable M6809/H6309/OS9 Disassembler                                                                      *
 * Copyright (c) 2000,2013  Arto Salmi 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ***************************************************************************/

/* NOTE! os9 call table is not tested. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef TYPES
#define TYPES
typedef unsigned char  byte;
typedef unsigned short word;
#endif

#ifndef NULL
#define NULL 0
#endif

byte *memory = NULL;

#define OPCODE(address)  memory[address&0xffff]
#define ARGBYTE(address) memory[address&0xffff]
#define ARGWORD(address) (word)((memory[address&0xffff]<<8)|memory[(address+1)&0xffff])

#include "dasm09.h"

static char *Options[]=
{
 "begin","end","offset","out","noaddr","nohex","x","os9", NULL
};

void usage(void)
{
   printf("Usage: dasm09 [options] <filename>\n"
          "Available options are:\n"
          " -begin  - start disassembly address [offset]\n"
          " -end    - end disassembly address  [auto]\n"
          " -offset - address to load program [0]\n"
          " -out    - output file [stdout]\n"
          " -noaddr - no address dump\n"
          " -nohex  - no hex dump\n"
          " -x      - use 6309 opcodes\n"
          " -os9    - patch swi2 (os9 call)\n"
          "All values should be entered in hexadecimal\n");

   exit(1);
}


int main(int argc, char *argv[])
{
   unsigned begin=0,end=0,offset=0,pc,add;
   char *fname=NULL,*outname=NULL;
   int showhex=TRUE,showaddr=TRUE;
   int i,j,n;
   char buf[30];
   int off;
   FILE *f;
   FILE *out=stdout;

   printf("dasm09: M6809/H6309/OS9 disassembler V0.1 © 2000 Arto Salmi\n");

   for (i=1,n=0;i<argc;++i)
   {
      if (argv[i][0]!='-')
      {
         switch (++n)
         {
            case 1:  fname=argv[i];
                     break;
           default:  usage();
         }
      }
      else
      {
         for (j=0;Options[j];++j)
         if (!strcmp(argv[i]+1,Options[j])) break;
         switch (j)
         {
         case 0:  ++i; if (i>argc) usage();
                  begin=strtoul(argv[i],NULL,16);
                  break;
         case 1:  ++i; if (i>argc) usage();
                  end=strtoul(argv[i],NULL,16);
                  break;
         case 2:  ++i; if (i>argc) usage();
                  offset=strtoul(argv[i],NULL,16);
                  break;
         case 3:  ++i; if (i>argc) usage();
                  outname=argv[i];
                  break;
         case 4:  showaddr=FALSE;break;
         case 5:  showhex=FALSE;break;

         case 6:  codes             = h6309_codes;
                  codes10           = h6309_codes10;
                  codes11           = h6309_codes11;
                  exg_tfr           = h6309_exg_tfr;
                  allow_6309_codes  = TRUE;
                  break;

           case 7: os9_patch = TRUE; break;

         default: usage();
         }
      }
   }

   f=fopen(fname,"rb");
   if(!f) usage();
   if(!end)
   {
      fseek(f,0,SEEK_END);
      off=ftell(f);
      end=(offset+off)-1;
      rewind(f);
   }

   if(!begin) if(offset) begin=offset;

   if(outname)
   {
      out=fopen(outname,"w");
      if(!out) printf("can't open %s \n",outname);
   }

   memory=(byte *)malloc(0x10000);
   if(!memory) {printf("no mem buffer\n");goto exit;}
   memset(memory,0x01,0x10000);
   fread(&memory[offset&0xFFFF],sizeof(byte),0x10000-(offset&0xFFFF),f);

   begin&=0xFFFF;
   end&=0xFFFF;
   pc=begin;

   fprintf(out,"; org $%04X \n",pc);

   do
   {
     if(showaddr) fprintf(out,"%04X: ",pc);
     add=Dasm(buf,pc);

     if(showhex)
     {
       for(i=0;i<5;i++)
       {
         if(add) {add--;fprintf(out,"%02X ",memory[(pc++)&0xFFFF]);}
         else fprintf(out,"   ");
       }
     } else pc+=add;

     if((!showaddr)&&(!showhex)) fprintf(out,"\t");

     fprintf(out,"%s \n",buf);
   } while( pc <= end);

   printf("Done\n");

   exit:
   if(f)       fclose(f);
   if(outname) if(out)    fclose(out);
   if(memory)  free(memory);

   return(0);
}
