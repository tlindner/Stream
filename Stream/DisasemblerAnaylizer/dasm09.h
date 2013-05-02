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

/***************************************************************************
                                     NOTES
                                     -----

 You need following functions/macros:
 OPCODE(address)    -    Fetch opcode
 ARGBYTE(address)   -    Fetch opcode argument 8 bit
 ARGWORD(address)   -    Fetch opcode argument 16 bit

 If you use Dasm() directly (faster), make sure that
 you use correct pointers.

 OS9 support: set variable os9_patch = TRUE
              os9 call table is not tested.

 ***************************************************************************/

#ifndef TYPES
#define TYPES
typedef unsigned char  byte;
typedef unsigned short word;
#endif

#ifndef FALSE
#define FALSE 0L
#define TRUE  1L
#endif

unsigned Dasm6809(char *buffer, unsigned pc, unsigned *pc_mode, unsigned *address);
unsigned Dasm6309(char *buffer, unsigned pc, unsigned *pc_mode, unsigned *address);

enum addr_mode {
_nom,     /* no mode                    */
_imp,     /* inherent/implied           */
_imb,     /* immediate byte             */
_imw,     /* immediate word             */
_dir,     /* direct                     */
_ext,     /* extended                   */
_ind,     /* indexed                    */
_reb,     /* relative byte              */
_rew,     /* relative word              */
_r1 ,     /* tfr/exg mode               */
_r2 ,     /* pul/psh system             */
_r3 ,     /* pul/psh user               */
_bd ,     /* Bit Manipulation direct    */
_bi ,     /* Bit Manipulation index     */
_be ,     /* Bit Manipulation extended  */
_bt ,     /* Bit Transfers direct       */
_t1 ,     /* Block Transfer r0+,r1+     */
_t2 ,     /* Block Transfer r0-,r1-     */
_t3 ,     /* Block Transfer r0+,r1      */
_t4 ,     /* Block Transfer r0,r1+      */
_iml      /* immediate 32-bit           */
};

enum pc_mode {
_pc_nop,     /* no effect                       */
_pc_jmp,     /* jump                            */
_pc_bra,     /* branch, or subroutine jump      */
_pc_tfr,     /* register transfer               */
_pc_ret,     /* return from subroutine          */
_pc_pul,     /* possible end of execution       */
_pc_end      /* end of execution                */
};

enum opcodes {
_ill=0,_abx,  _adca, _adcb, _adda, _addb, _addd, _anda, _andb,
_andcc,_asla, _aslb, _asl,  _asra, _asrb, _asr,  _bcc,  _lbcc,
_bcs,  _lbcs, _beq,  _lbeq, _bge,  _lbge, _bgt,  _lbgt, _bhi,
_lbhi, _bita, _bitb, _ble,  _lble, _bls,  _lbls, _blt,  _lblt,
_bmi,  _lbmi, _bne,  _lbne, _bpl,  _lbpl, _bra,  _lbra, _brn,
_lbrn, _bsr,  _lbsr, _bvc,  _lbvc, _bvs,  _lbvs, _clra, _clrb,
_clr,  _cmpa, _cmpb, _cmpd, _cmps, _cmpu, _cmpx, _cmpy, _coma,
_comb, _com,  _cwai, _daa,  _deca, _decb, _dec,  _eora, _eorb,
_exg,  _inca, _incb, _inc,  _jmp,  _jsr,  _lda,  _ldb,  _ldd,
_lds,  _ldu,  _ldx,  _ldy,  _leas, _leau, _leax, _leay, _lsra,
_lsrb, _lsr,  _mul,  _nega, _negb, _neg,  _nop,  _ora,  _orb,
_orcc, _pshs, _pshu, _puls, _pulu, _rola, _rolb, _rol,  _rora,
_rorb, _ror,  _rti,  _rts,  _sbca, _sbcb, _sex,  _sta,  _stb,
_std,  _sts,  _stu,  _stx,  _sty,  _suba, _subb, _subd, _swi,
_swi2, _swi3, _sync, _tfr,  _tsta, _tstb, _tst,  _reset,
/* 6309 extra opcodes */
_aim,  _eim,  _oim,  _tim,  _band, _biand,_bor,  _bior, _beor,
_bieor,_ldbt, _stbt, _tfm,  _adcd, _adcr, _adde, _addf, _addw,
_addr, _andd, _andr, _asld, _asrd, _bitd, _bitmd,_clrd, _clre,
_clrf, _clrw, _cmpe, _cmpf, _cmpw, _cmpr, _comd, _come, _comf,
_comw, _decd, _dece, _decf, _decw, _divd, _divq, _eord, _eorr,
_incd, _ince, _incf, _incw, _lde,  _ldf,  _ldq,  _ldw,  _ldmd,
_lsrd, _lsrw, _muld, _negd, _ord,  _orr,  _pshsw,_pshuw,_pulsw,
_puluw,_rold, _rolw, _rord, _rorw, _sbcd, _sbcr, _sexw, _ste,
_stf,  _stq,  _stw,  _sube, _subf, _subw, _subr, _tstd, _tste,
_tstf, _tstw
};

char *mne[] = {
"???",  "ABX",  "ADCA", "ADCB", "ADDA", "ADDB", "ADDD", "ANDA", "ANDB",
"ANDCC","ASLA", "ASLB", "ASL",  "ASRA", "ASRB", "ASR",  "BCC",  "LBCC",
"BCS",  "LBCS", "BEQ",  "LBEQ", "BGE",  "LBGE", "BGT",  "LBGT", "BHI",
"LBHI", "BITA", "BITB", "BLE",  "LBLE", "BLS",  "LBLS", "BLT",  "LBLT",
"BMI",  "LBMI", "BNE",  "LBNE", "BPL",  "LBPL", "BRA",  "LBRA", "BRN",
"LBRN", "BSR",  "LBSR", "BVC",  "LBVC", "BVS",  "LBVS", "CLRA", "CLRB",
"CLR",  "CMPA", "CMPB", "CMPD", "CMPS", "CMPU", "CMPX", "CMPY", "COMA",
"COMB", "COM",  "CWAI", "DAA",  "DECA", "DECB", "DEC",  "EORA", "EORB",
"EXG",  "INCA", "INCB", "INC",  "JMP",  "JSR",  "LDA",  "LDB",  "LDD",
"LDS",  "LDU",  "LDX",  "LDY",  "LEAS", "LEAU", "LEAX", "LEAY", "LSRA",
"LSRB", "LSR",  "MUL",  "NEGA", "NEGB", "NEG",  "NOP",  "ORA",  "ORB",
"ORCC", "PSHS", "PSHU", "PULS", "PULU", "ROLA", "ROLB", "ROL",  "RORA",
"RORB", "ROR",  "RTI",  "RTS",  "SBCA", "SBCB", "SEX",  "STA",  "STB",
"STD",  "STS",  "STU",  "STX",  "STY",  "SUBA", "SUBB", "SUBD", "SWI",
"SWI2", "SWI3", "SYNC", "TFR",  "TSTA", "TSTB", "TST",  "RESET",
/* 6309 EXTRA OPCODES */
"AIM",  "EIM",  "OIM",  "TIM",  "BAND", "BIAND","BOR",  "BIOR", "BEOR",
"BIEOR","LDBT", "STBT", "TFM",  "ADCD", "ADCR", "ADDE", "ADDF", "ADDW",
"ADDR", "ANDD", "ANDR", "ASLD", "ASRD", "BITD", "BITMD","CLRD", "CLRE",
"CLRF", "CLRW", "CMPE", "CMPF", "CMPW", "CMPR", "COMD", "COME", "COMF",
"COMW", "DECD", "DECE", "DECF", "DECW", "DIVD", "DIVQ", "EORD", "EORR",
"INCD", "INCE", "INCF", "INCW", "LDE",  "LDF",  "LDQ",  "LDW",  "LDMD",
"LSRD", "LSRW", "MULD", "NEGD", "ORD",  "ORR",  "PSHSW","PSHUW","PULSW",
"PULUW","ROLD", "ROLW", "RORD", "RORW", "SBCD", "SBCR", "SEXW", "STE",
"STF",  "STQ",  "STW",  "SUBE", "SUBF", "SUBW", "SUBR", "TSTD", "TSTE",
"TSTF", "TSTW"
};

char *os9_codes[0x100] = {
"F$Link",      "F$Load",      "F$UnLink",    "F$Fork",
"F$Wait",      "F$Chain",     "F$Exit",      "F$Mem",
"F$Send",      "F$Icpt",      "F$Sleep",     "F$SSpd",
"F$ID",        "F$SPrior",    "F$SSWI",      "F$Perr",
"F$PrsNam",    "F$CmpNam",    "F$SchBit",    "F$AllBit",
"F$DelBit",    "F$Time",      "F$STime",     "F$CRC",
"F$GPrDsc",    "F$GBlkMp",    "F$GModDr",    "F$CpyMem",
"F$SUser",     "F$UnLoad",    "F$Alarm",     "F$",
"F$",          "F$NMLink",    "F$NMLoad",    "F$Ctime",
"F$Cstime",    "F$CTswi2",    "F$",          "F$VIRQ",
"F$SRqMem",    "F$SRtMem",    "F$IRQ",       "F$IOQu",
"F$AProc",     "F$NProc",     "F$VModul",    "F$Find64",
"F$All64",     "F$Ret64",     "F$SSvc",      "F$IODel",
"F$SLink",     "F$Boot",      "F$BtMem",     "F$GProcP",
"F$Move",      "F$AllRAM",    "F$AllImg",    "F$DelImg",
"F$SetImg",    "F$FreeLB",    "F$FreeHB",    "F$AllTsk",
"F$DelTsk",    "F$SetTsk",    "F$ResTsk",    "F$RelTsk",
"F$DATLog",    "F$DATTmp",    "F$LDAXY",     "F$LDAXYP",
"F$LDDDXY",    "F$LDABX",     "F$STABX",     "F$AllPrc",
"F$DelPrc",    "F$ELink",     "F$FModul",    "F$MapBlk",
"F$ClrBlk",    "F$DelRAM",    "F$GCMDir",    "F$AlHRam",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"I$Attach",    "I$Detach",    "I$Dup",       "I$Create",
"I$Open",      "I$MakDir",    "I$Chgdir",    "I$Delete",
"I$Seek",      "I$Read",      "I$Write",     "I$ReadLn",
"I$WritLn",    "I$GetStt",    "I$SetStt",    "I$Close",
"I$DeletX",    "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$",
"F$",          "F$",          "F$",          "F$"
};

byte h6309_codes[768] = {
    _neg  ,_dir, _pc_nop,    _oim  ,_bd , _pc_nop,    _aim  ,_bd , _pc_nop,    _com  ,_dir, _pc_nop,
    _lsr  ,_dir, _pc_nop,    _eim  ,_bd , _pc_nop,    _ror  ,_dir, _pc_nop,    _asr  ,_dir, _pc_nop,
    _asl  ,_dir, _pc_nop,    _rol  ,_dir, _pc_nop,    _dec  ,_dir, _pc_nop,    _tim  ,_bd , _pc_nop,
    _inc  ,_dir, _pc_nop,    _tst  ,_dir, _pc_nop,    _jmp  ,_dir, _pc_jmp,    _clr  ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _nop  ,_imp, _pc_nop,    _sync ,_imp, _pc_nop,
    _sexw ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _lbra ,_rew, _pc_nop,    _lbsr ,_rew, _pc_nop,
    _ill  ,_nom, _pc_nop,    _daa  ,_imp, _pc_nop,    _orcc ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,
    _andcc,_imb, _pc_nop,    _sex  ,_imp, _pc_nop,    _exg  ,_r1 , _pc_nop,    _tfr  ,_r1 , _pc_nop,
    _bra  ,_reb, _pc_nop,    _brn  ,_reb, _pc_nop,    _bhi  ,_reb, _pc_nop,    _bls  ,_reb, _pc_nop,
    _bcc  ,_reb, _pc_nop,    _bcs  ,_reb, _pc_nop,    _bne  ,_reb, _pc_nop,    _beq  ,_reb, _pc_nop,
    _bvc  ,_reb, _pc_nop,    _bvs  ,_reb, _pc_nop,    _bpl  ,_reb, _pc_nop,    _bmi  ,_reb, _pc_nop,
    _bge  ,_reb, _pc_nop,    _blt  ,_reb, _pc_nop,    _bgt  ,_reb, _pc_nop,    _ble  ,_reb, _pc_nop,
    _leax ,_ind, _pc_nop,    _leay ,_ind, _pc_nop,    _leas ,_ind, _pc_nop,    _leau ,_ind, _pc_nop,
    _pshs ,_r2 , _pc_nop,    _puls ,_r2 , _pc_nop,    _pshu ,_r3 , _pc_nop,    _pulu ,_r3 , _pc_nop,
    _ill  ,_nom, _pc_nop,    _rts  ,_imp, _pc_nop,    _abx  ,_imp, _pc_nop,    _rti  ,_imp, _pc_nop,
    _cwai ,_imb, _pc_nop,    _mul  ,_imp, _pc_nop,    _reset,_imp, _pc_nop,    _swi  ,_imp, _pc_nop,
    _nega ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _coma ,_imp, _pc_nop,
    _lsra ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _rora ,_imp, _pc_nop,    _asra ,_imp, _pc_nop,
    _asla ,_imp, _pc_nop,    _rola ,_imp, _pc_nop,    _deca ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,
    _inca ,_imp, _pc_nop,    _tsta ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _clra ,_imp, _pc_nop,
    _negb ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _comb ,_imp, _pc_nop,
    _lsrb ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _rorb ,_imp, _pc_nop,    _asrb ,_imp, _pc_nop,
    _aslb ,_imp, _pc_nop,    _rolb ,_imp, _pc_nop,    _decb ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,
    _incb ,_imp, _pc_nop,    _tstb ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _clrb ,_imp, _pc_nop,
    _neg  ,_ind, _pc_nop,    _oim  ,_bi , _pc_nop,    _aim  ,_bi , _pc_nop,    _com  ,_ind, _pc_nop,
    _lsr  ,_ind, _pc_nop,    _eim  ,_bi , _pc_nop,    _ror  ,_ind, _pc_nop,    _asr  ,_ind, _pc_nop,
    _asl  ,_ind, _pc_nop,    _rol  ,_ind, _pc_nop,    _dec  ,_ind, _pc_nop,    _tim  ,_bi , _pc_nop,
    _inc  ,_ind, _pc_nop,    _tst  ,_ind, _pc_nop,    _jmp  ,_ind, _pc_jmp,    _clr  ,_ind, _pc_nop,
    _neg  ,_ext, _pc_nop,    _oim  ,_be , _pc_nop,    _aim  ,_be , _pc_nop,    _com  ,_ext, _pc_nop,
    _lsr  ,_ext, _pc_nop,    _eim  ,_be , _pc_nop,    _ror  ,_ext, _pc_nop,    _asr  ,_ext, _pc_nop,
    _asl  ,_ext, _pc_nop,    _rol  ,_ext, _pc_nop,    _dec  ,_ext, _pc_nop,    _tim  ,_be , _pc_nop,
    _inc  ,_ext, _pc_nop,    _tst  ,_ext, _pc_nop,    _jmp  ,_ext, _pc_jmp,    _clr  ,_ext, _pc_nop,
    _suba ,_imb, _pc_nop,    _cmpa ,_imb, _pc_nop,    _sbca ,_imb, _pc_nop,    _subd ,_imw, _pc_nop,
    _anda ,_imb, _pc_nop,    _bita ,_imb, _pc_nop,    _lda  ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,
    _eora ,_imb, _pc_nop,    _adca ,_imb, _pc_nop,    _ora  ,_imb, _pc_nop,    _adda ,_imb, _pc_nop,
    _cmpx ,_imw, _pc_nop,    _bsr  ,_reb, _pc_nop,    _ldx  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,
    _suba ,_dir, _pc_nop,    _cmpa ,_dir, _pc_nop,    _sbca ,_dir, _pc_nop,    _subd ,_dir, _pc_nop,
    _anda ,_dir, _pc_nop,    _bita ,_dir, _pc_nop,    _lda  ,_dir, _pc_nop,    _sta  ,_dir, _pc_nop,
    _eora ,_dir, _pc_nop,    _adca ,_dir, _pc_nop,    _ora  ,_dir, _pc_nop,    _adda ,_dir, _pc_nop,
    _cmpx ,_dir, _pc_nop,    _jsr  ,_dir, _pc_nop,    _ldx  ,_dir, _pc_nop,    _stx  ,_dir, _pc_nop,
    _suba ,_ind, _pc_nop,    _cmpa ,_ind, _pc_nop,    _sbca ,_ind, _pc_nop,    _subd ,_ind, _pc_nop,
    _anda ,_ind, _pc_nop,    _bita ,_ind, _pc_nop,    _lda  ,_ind, _pc_nop,    _sta  ,_ind, _pc_nop,
    _eora ,_ind, _pc_nop,    _adca ,_ind, _pc_nop,    _ora  ,_ind, _pc_nop,    _adda ,_ind, _pc_nop,
    _cmpx ,_ind, _pc_nop,    _jsr  ,_ind, _pc_nop,    _ldx  ,_ind, _pc_nop,    _stx  ,_ind, _pc_nop,
    _suba ,_ext, _pc_nop,    _cmpa ,_ext, _pc_nop,    _sbca ,_ext, _pc_nop,    _subd ,_ext, _pc_nop,
    _anda ,_ext, _pc_nop,    _bita ,_ext, _pc_nop,    _lda  ,_ext, _pc_nop,    _sta  ,_ext, _pc_nop,
    _eora ,_ext, _pc_nop,    _adca ,_ext, _pc_nop,    _ora  ,_ext, _pc_nop,    _adda ,_ext, _pc_nop,
    _cmpx ,_ext, _pc_nop,    _jsr  ,_ext, _pc_nop,    _ldx  ,_ext, _pc_nop,    _stx  ,_ext, _pc_nop,
    _subb ,_imb, _pc_nop,    _cmpb ,_imb, _pc_nop,    _sbcb ,_imb, _pc_nop,    _addd ,_imw, _pc_nop,
    _andb ,_imb, _pc_nop,    _bitb ,_imb, _pc_nop,    _ldb  ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,
    _eorb ,_imb, _pc_nop,    _adcb ,_imb, _pc_nop,    _orb  ,_imb, _pc_nop,    _addb ,_imb, _pc_nop,
    _ldd  ,_imw, _pc_nop,    _ldq  ,_iml, _pc_nop,    _ldu  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,
    _subb ,_dir, _pc_nop,    _cmpb ,_dir, _pc_nop,    _sbcb ,_dir, _pc_nop,    _addd ,_dir, _pc_nop,
    _andb ,_dir, _pc_nop,    _bitb ,_dir, _pc_nop,    _ldb  ,_dir, _pc_nop,    _stb  ,_dir, _pc_nop,
    _eorb ,_dir, _pc_nop,    _adcb ,_dir, _pc_nop,    _orb  ,_dir, _pc_nop,    _addb ,_dir, _pc_nop,
    _ldd  ,_dir, _pc_nop,    _std  ,_dir, _pc_nop,    _ldu  ,_dir, _pc_nop,    _stu  ,_dir, _pc_nop,
    _subb ,_ind, _pc_nop,    _cmpb ,_ind, _pc_nop,    _sbcb ,_ind, _pc_nop,    _addd ,_ind, _pc_nop,
    _andb ,_ind, _pc_nop,    _bitb ,_ind, _pc_nop,    _ldb  ,_ind, _pc_nop,    _stb  ,_ind, _pc_nop,
    _eorb ,_ind, _pc_nop,    _adcb ,_ind, _pc_nop,    _orb  ,_ind, _pc_nop,    _addb ,_ind, _pc_nop,
    _ldd  ,_ind, _pc_nop,    _std  ,_ind, _pc_nop,    _ldu  ,_ind, _pc_nop,    _stu  ,_ind, _pc_nop,
    _subb ,_ext, _pc_nop,    _cmpb ,_ext, _pc_nop,    _sbcb ,_ext, _pc_nop,    _addd ,_ext, _pc_nop,
    _andb ,_ext, _pc_nop,    _bitb ,_ext, _pc_nop,    _ldb  ,_ext, _pc_nop,    _stb  ,_ext, _pc_nop,
    _eorb ,_ext, _pc_nop,    _adcb ,_ext, _pc_nop,    _orb  ,_ext, _pc_nop,    _addb ,_ext, _pc_nop,
    _ldd  ,_ext, _pc_nop,    _std  ,_ext, _pc_nop,    _ldu  ,_ext, _pc_nop,    _stu  ,_ext, _pc_nop,
};

byte m6809_codes[768] = {
    _neg  ,_dir, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _com  ,_dir, _pc_nop,
    _lsr  ,_dir, _pc_nop,    _ill  ,_nom, _pc_nop,    _ror  ,_dir, _pc_nop,    _asr  ,_dir, _pc_nop,
    _asl  ,_dir, _pc_nop,    _rol  ,_dir, _pc_nop,    _dec  ,_dir, _pc_nop,    _ill  ,_nom, _pc_nop,
    _inc  ,_dir, _pc_nop,    _tst  ,_dir, _pc_nop,    _jmp  ,_dir, _pc_jmp,    _clr  ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _nop  ,_imp, _pc_nop,    _sync ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lbra ,_rew, _pc_nop,    _lbsr ,_rew, _pc_nop,
    _ill  ,_nom, _pc_nop,    _daa  ,_imp, _pc_nop,    _orcc ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,
    _andcc,_imb, _pc_nop,    _sex  ,_imp, _pc_nop,    _exg  ,_r1 , _pc_nop,    _tfr  ,_r1 , _pc_nop,
    _bra  ,_reb, _pc_nop,    _brn  ,_reb, _pc_nop,    _bhi  ,_reb, _pc_nop,    _bls  ,_reb, _pc_nop,
    _bcc  ,_reb, _pc_nop,    _bcs  ,_reb, _pc_nop,    _bne  ,_reb, _pc_nop,    _beq  ,_reb, _pc_nop,
    _bvc  ,_reb, _pc_nop,    _bvs  ,_reb, _pc_nop,    _bpl  ,_reb, _pc_nop,    _bmi  ,_reb, _pc_nop,
    _bge  ,_reb, _pc_nop,    _blt  ,_reb, _pc_nop,    _bgt  ,_reb, _pc_nop,    _ble  ,_reb, _pc_nop,
    _leax ,_ind, _pc_nop,    _leay ,_ind, _pc_nop,    _leas ,_ind, _pc_nop,    _leau ,_ind, _pc_nop,
    _pshs ,_r2 , _pc_nop,    _puls ,_r2 , _pc_nop,    _pshu ,_r3 , _pc_nop,    _pulu ,_r3 , _pc_nop,
    _ill  ,_nom, _pc_nop,    _rts  ,_imp, _pc_nop,    _abx  ,_imp, _pc_nop,    _rti  ,_imp, _pc_nop,
    _cwai ,_imb, _pc_nop,    _mul  ,_imp, _pc_nop,    _reset,_imp, _pc_nop,    _swi  ,_imp, _pc_nop,
    _nega ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _coma ,_imp, _pc_nop,
    _lsra ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _rora ,_imp, _pc_nop,    _asra ,_imp, _pc_nop,
    _asla ,_imp, _pc_nop,    _rola ,_imp, _pc_nop,    _deca ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,
    _inca ,_imp, _pc_nop,    _tsta ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _clra ,_imp, _pc_nop,
    _negb ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _comb ,_imp, _pc_nop,
    _lsrb ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _rorb ,_imp, _pc_nop,    _asrb ,_imp, _pc_nop,
    _aslb ,_imp, _pc_nop,    _rolb ,_imp, _pc_nop,    _decb ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,
    _incb ,_imp, _pc_nop,    _tstb ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _clrb ,_imp, _pc_nop,
    _neg  ,_ind, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _com  ,_ind, _pc_nop,
    _lsr  ,_ind, _pc_nop,    _ill  ,_nom, _pc_nop,    _ror  ,_ind, _pc_nop,    _asr  ,_ind, _pc_nop,
    _asl  ,_ind, _pc_nop,    _rol  ,_ind, _pc_nop,    _dec  ,_ind, _pc_nop,    _ill  ,_nom, _pc_nop,
    _inc  ,_ind, _pc_nop,    _tst  ,_ind, _pc_nop,    _jmp  ,_ind, _pc_jmp,    _clr  ,_ind, _pc_nop,
    _neg  ,_ext, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _com  ,_ext, _pc_nop,
    _lsr  ,_ext, _pc_nop,    _ill  ,_nom, _pc_nop,    _ror  ,_ext, _pc_nop,    _asr  ,_ext, _pc_nop,
    _asl  ,_ext, _pc_nop,    _rol  ,_ext, _pc_nop,    _dec  ,_ext, _pc_nop,    _ill  ,_nom, _pc_nop,
    _inc  ,_ext, _pc_nop,    _tst  ,_ext, _pc_nop,    _jmp  ,_ext, _pc_jmp,    _clr  ,_ext, _pc_nop,
    _suba ,_imb, _pc_nop,    _cmpa ,_imb, _pc_nop,    _sbca ,_imb, _pc_nop,    _subd ,_imw, _pc_nop,
    _anda ,_imb, _pc_nop,    _bita ,_imb, _pc_nop,    _lda  ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,
    _eora ,_imb, _pc_nop,    _adca ,_imb, _pc_nop,    _ora  ,_imb, _pc_nop,    _adda ,_imb, _pc_nop,
    _cmpx ,_imw, _pc_nop,    _bsr  ,_reb, _pc_nop,    _ldx  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,
    _suba ,_dir, _pc_nop,    _cmpa ,_dir, _pc_nop,    _sbca ,_dir, _pc_nop,    _subd ,_dir, _pc_nop,
    _anda ,_dir, _pc_nop,    _bita ,_dir, _pc_nop,    _lda  ,_dir, _pc_nop,    _sta  ,_dir, _pc_nop,
    _eora ,_dir, _pc_nop,    _adca ,_dir, _pc_nop,    _ora  ,_dir, _pc_nop,    _adda ,_dir, _pc_nop,
    _cmpx ,_dir, _pc_nop,    _jsr  ,_dir, _pc_nop,    _ldx  ,_dir, _pc_nop,    _stx  ,_dir, _pc_nop,
    _suba ,_ind, _pc_nop,    _cmpa ,_ind, _pc_nop,    _sbca ,_ind, _pc_nop,    _subd ,_ind, _pc_nop,
    _anda ,_ind, _pc_nop,    _bita ,_ind, _pc_nop,    _lda  ,_ind, _pc_nop,    _sta  ,_ind, _pc_nop,
    _eora ,_ind, _pc_nop,    _adca ,_ind, _pc_nop,    _ora  ,_ind, _pc_nop,    _adda ,_ind, _pc_nop,
    _cmpx ,_ind, _pc_nop,    _jsr  ,_ind, _pc_nop,    _ldx  ,_ind, _pc_nop,    _stx  ,_ind, _pc_nop,
    _suba ,_ext, _pc_nop,    _cmpa ,_ext, _pc_nop,    _sbca ,_ext, _pc_nop,    _subd ,_ext, _pc_nop,
    _anda ,_ext, _pc_nop,    _bita ,_ext, _pc_nop,    _lda  ,_ext, _pc_nop,    _sta  ,_ext, _pc_nop,
    _eora ,_ext, _pc_nop,    _adca ,_ext, _pc_nop,    _ora  ,_ext, _pc_nop,    _adda ,_ext, _pc_nop,
    _cmpx ,_ext, _pc_nop,    _jsr  ,_ext, _pc_nop,    _ldx  ,_ext, _pc_nop,    _stx  ,_ext, _pc_nop,
    _subb ,_imb, _pc_nop,    _cmpb ,_imb, _pc_nop,    _sbcb ,_imb, _pc_nop,    _addd ,_imw, _pc_nop,
    _andb ,_imb, _pc_nop,    _bitb ,_imb, _pc_nop,    _ldb  ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,
    _eorb ,_imb, _pc_nop,    _adcb ,_imb, _pc_nop,    _orb  ,_imb, _pc_nop,    _addb ,_imb, _pc_nop,
    _ldd  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldu  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,
    _subb ,_dir, _pc_nop,    _cmpb ,_dir, _pc_nop,    _sbcb ,_dir, _pc_nop,    _addd ,_dir, _pc_nop,
    _andb ,_dir, _pc_nop,    _bitb ,_dir, _pc_nop,    _ldb  ,_dir, _pc_nop,    _stb  ,_dir, _pc_nop,
    _eorb ,_dir, _pc_nop,    _adcb ,_dir, _pc_nop,    _orb  ,_dir, _pc_nop,    _addb ,_dir, _pc_nop,
    _ldd  ,_dir, _pc_nop,    _std  ,_dir, _pc_nop,    _ldu  ,_dir, _pc_nop,    _stu  ,_dir, _pc_nop,
    _subb ,_ind, _pc_nop,    _cmpb ,_ind, _pc_nop,    _sbcb ,_ind, _pc_nop,    _addd ,_ind, _pc_nop,
    _andb ,_ind, _pc_nop,    _bitb ,_ind, _pc_nop,    _ldb  ,_ind, _pc_nop,    _stb  ,_ind, _pc_nop,
    _eorb ,_ind, _pc_nop,    _adcb ,_ind, _pc_nop,    _orb  ,_ind, _pc_nop,    _addb ,_ind, _pc_nop,
    _ldd  ,_ind, _pc_nop,    _std  ,_ind, _pc_nop,    _ldu  ,_ind, _pc_nop,    _stu  ,_ind, _pc_nop,
    _subb ,_ext, _pc_nop,    _cmpb ,_ext, _pc_nop,    _sbcb ,_ext, _pc_nop,    _addd ,_ext, _pc_nop,
    _andb ,_ext, _pc_nop,    _bitb ,_ext, _pc_nop,    _ldb  ,_ext, _pc_nop,    _stb  ,_ext, _pc_nop,
    _eorb ,_ext, _pc_nop,    _adcb ,_ext, _pc_nop,    _orb  ,_ext, _pc_nop,    _addb ,_ext, _pc_nop,
    _ldd  ,_ext, _pc_nop,    _std  ,_ext, _pc_nop,    _ldu  ,_ext, _pc_nop,    _stu  ,_ext, _pc_nop,
};

byte h6309_codes10[768] = {
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _lbrn ,_rew, _pc_nop,    _lbhi ,_rew, _pc_nop,    _lbls ,_rew, _pc_nop,
    _lbcc ,_rew, _pc_nop,    _lbcs ,_rew, _pc_nop,    _lbne ,_rew, _pc_nop,    _lbeq ,_rew, _pc_nop,
    _lbvc ,_rew, _pc_nop,    _lbvs ,_rew, _pc_nop,    _lbpl ,_rew, _pc_nop,    _lbmi ,_rew, _pc_nop,
    _lbge ,_rew, _pc_nop,    _lblt ,_rew, _pc_nop,    _lbgt ,_rew, _pc_nop,    _lble ,_rew, _pc_nop,
    _addr ,_r1 , _pc_nop,    _adcr ,_r1 , _pc_nop,    _subr ,_r1 , _pc_nop,    _sbcr ,_r1 , _pc_nop,
    _andr ,_r1 , _pc_nop,    _orr  ,_r1 , _pc_nop,    _eorr ,_r1 , _pc_nop,    _cmpr ,_r1 , _pc_nop,
    _pshsw,_imp, _pc_nop,    _pulsw,_imp, _pc_nop,    _pshuw,_imp, _pc_nop,    _puluw,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _swi2 ,_imp, _pc_nop,
    _negd ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _comd ,_imp, _pc_nop,
    _lsrd ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _rord ,_imp, _pc_nop,    _asrd ,_imp, _pc_nop,
    _asld ,_imp, _pc_nop,    _rold ,_imp, _pc_nop,    _decd ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,
    _incd ,_imp, _pc_nop,    _tstd ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _clrd ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _comw ,_imp, _pc_nop,
    _lsrw ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _rorw ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _rolw ,_imp, _pc_nop,    _decw ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,
    _incw ,_imp, _pc_nop,    _tstw ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _clrw ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _subw ,_imw, _pc_nop,    _cmpw ,_imw, _pc_nop,    _sbcd ,_imw, _pc_nop,    _cmpd ,_imw, _pc_nop,
    _andd ,_imw, _pc_nop,    _bitd ,_imw, _pc_nop,    _ldw  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,
    _eord ,_imw, _pc_nop,    _adcd ,_imw, _pc_nop,    _ord  ,_imw, _pc_nop,    _addw ,_imw, _pc_nop,
    _cmpy ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldy  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,
    _subw ,_dir, _pc_nop,    _cmpw ,_dir, _pc_nop,    _sbcd ,_dir, _pc_nop,    _cmpd ,_dir, _pc_nop,
    _andd ,_dir, _pc_nop,    _bitd ,_dir, _pc_nop,    _ldw  ,_dir, _pc_nop,    _stw  ,_dir, _pc_nop,
    _eord ,_dir, _pc_nop,    _adcd ,_dir, _pc_nop,    _ord  ,_dir, _pc_nop,    _addw ,_dir, _pc_nop,
    _cmpy ,_dir, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldy  ,_dir, _pc_nop,    _sty  ,_dir, _pc_nop,
    _subw ,_ind, _pc_nop,    _cmpw ,_ind, _pc_nop,    _sbcd ,_ind, _pc_nop,    _cmpd ,_ind, _pc_nop,
    _andd ,_ind, _pc_nop,    _bitd ,_ind, _pc_nop,    _ldw  ,_ind, _pc_nop,    _stw  ,_ind, _pc_nop,
    _eord ,_ind, _pc_nop,    _adcd ,_ind, _pc_nop,    _ord  ,_ind, _pc_nop,    _addw ,_ind, _pc_nop,
    _cmpy ,_ind, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldy  ,_ind, _pc_nop,    _sty  ,_ind, _pc_nop,
    _subw ,_ext, _pc_nop,    _cmpw ,_ext, _pc_nop,    _sbcd ,_ext, _pc_nop,    _cmpd ,_ext, _pc_nop,
    _andd ,_ext, _pc_nop,    _bitd ,_ext, _pc_nop,    _ldw  ,_ext, _pc_nop,    _stw  ,_ext, _pc_nop,
    _eord ,_ext, _pc_nop,    _adcd ,_ext, _pc_nop,    _ord  ,_ext, _pc_nop,    _addw ,_ext, _pc_nop,
    _cmpy ,_ext, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldy  ,_ext, _pc_nop,    _sty  ,_ext, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lds  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ldq  ,_dir, _pc_nop,    _stq  ,_dir, _pc_nop,    _lds  ,_dir, _pc_nop,    _sts  ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ldq  ,_ind, _pc_nop,    _stq  ,_ind, _pc_nop,    _lds  ,_ind, _pc_nop,    _sts  ,_ind, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ldq  ,_ext, _pc_nop,    _stq  ,_ext, _pc_nop,    _lds  ,_ext, _pc_nop,    _sts  ,_ext, _pc_nop,
};

byte m6809_codes10[768] = {
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _lbrn ,_rew, _pc_nop,    _lbhi ,_rew, _pc_nop,    _lbls ,_rew, _pc_nop,
    _lbcc ,_rew, _pc_nop,    _lbcs ,_rew, _pc_nop,    _lbne ,_rew, _pc_nop,    _lbeq ,_rew, _pc_nop,
    _lbvc ,_rew, _pc_nop,    _lbvs ,_rew, _pc_nop,    _lbpl ,_rew, _pc_nop,    _lbmi ,_rew, _pc_nop,
    _lbge ,_rew, _pc_nop,    _lblt ,_rew, _pc_nop,    _lbgt ,_rew, _pc_nop,    _lble ,_rew, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _swi2 ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpd ,_imw, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _cmpy ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldy  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpd ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _cmpy ,_dir, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldy  ,_dir, _pc_nop,    _sty  ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpd ,_ind, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _cmpy ,_ind, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldy  ,_ind, _pc_nop,    _sty  ,_ind, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpd ,_ext, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _cmpy ,_ext, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldy  ,_ext, _pc_nop,    _sty  ,_ext, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lds  ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lds  ,_dir, _pc_nop,    _sts  ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lds  ,_ind, _pc_nop,    _sts  ,_ind, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lds  ,_ext, _pc_nop,    _sts  ,_ext, _pc_nop,
};

byte h6309_codes11[768] = {
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _band ,_bt , _pc_nop,    _biand,_bt , _pc_nop,    _bor  ,_bt , _pc_nop,    _bior ,_bt , _pc_nop,
    _beor ,_bt , _pc_nop,    _bieor,_bt , _pc_nop,    _ldbt ,_bt , _pc_nop,    _stbt ,_bt , _pc_nop,
    _tfm  ,_t1 , _pc_nop,    _tfm  ,_t2 , _pc_nop,    _tfm  ,_t3 , _pc_nop,    _tfm  ,_t4 , _pc_nop,
    _bitmd,_imb, _pc_nop,    _ldmd ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,    _swi3 ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _come ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _dece ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ince ,_imp, _pc_nop,    _tste ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _clre ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _comf ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _decf ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,
    _incf ,_imp, _pc_nop,    _tstf ,_imp, _pc_nop,    _ill  ,_nom, _pc_nop,    _clrf ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _sube ,_imb, _pc_nop,    _cmpe ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpu ,_imw, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lde  ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _adde ,_imb, _pc_nop,
    _cmps ,_imw, _pc_nop,    _divd ,_imb, _pc_nop,    _divq ,_imw, _pc_nop,    _muld ,_imw, _pc_nop,
    _sube ,_dir, _pc_nop,    _cmpe ,_dir, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpu ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lde  ,_dir, _pc_nop,    _ste  ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _adde ,_dir, _pc_nop,
    _cmps ,_dir, _pc_nop,    _divd ,_dir, _pc_nop,    _divq ,_dir, _pc_nop,    _muld ,_dir, _pc_nop,
    _sube ,_ind, _pc_nop,    _cmpe ,_ind, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpu ,_ind, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lde  ,_ind, _pc_nop,    _ste  ,_ind, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _adde ,_ind, _pc_nop,
    _cmps ,_ind, _pc_nop,    _divd ,_ind, _pc_nop,    _divq ,_ind, _pc_nop,    _muld ,_ind, _pc_nop,
    _sube ,_ext, _pc_nop,    _cmpe ,_ext, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpu ,_ext, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _lde  ,_ext, _pc_nop,    _ste  ,_ext, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _adde ,_ext, _pc_nop,
    _cmps ,_ext, _pc_nop,    _divd ,_ext, _pc_nop,    _divq ,_ext, _pc_nop,    _muld ,_ext, _pc_nop,
    _subf ,_imb, _pc_nop,    _cmpf ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldf  ,_imb, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _addf ,_imb, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _subf ,_dir, _pc_nop,    _cmpf ,_dir, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldf  ,_dir, _pc_nop,    _stf  ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _addf ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _subf ,_ind, _pc_nop,    _cmpf ,_ind, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldf  ,_ind, _pc_nop,    _stf  ,_ind, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _addf ,_ind, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _subf ,_ext, _pc_nop,    _cmpf ,_ext, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ldf  ,_ext, _pc_nop,    _stf  ,_ext, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _addf ,_ext, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
};

byte m6809_codes11[768] = {
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _swi3 ,_imp, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpu ,_imw, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _cmps ,_imw, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpu ,_dir, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _cmps ,_dir, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpu ,_ind, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _cmps ,_ind, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _cmpu ,_ext, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _cmps ,_ext, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,    _ill  ,_nom, _pc_nop,
};

char *h6309_exg_tfr[] =
{
 "D", "X", "Y", "U", "S", "PC","W" ,"V",
 "A", "B", "CC","DP","0", "0", "E", "F"
};

char *m6809_exg_tfr[] =
{
 "D", "X", "Y", "U", "S", "PC","??","??",
 "A", "B", "CC","DP","??","??","??","??"
};

char *bit_r[] = {"CC","A","B","??"};

char *block_r[] =
{
 "D","X","Y","U","S","?","?","?","?","?","?","?","?","?","?","?"
};

char *off4[] =
{
  "0",  "1",  "2",  "3",  "4",  "5",  "6",  "7",
  "8",  "9", "10", "11", "12", "13", "14", "15",
"-16","-15","-14","-13","-12","-11","-10", "-9",
 "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1"
};

char reg[] = { 'X','Y','U','S' };

byte *codes            = m6809_codes;
byte *codes10          = m6809_codes10;
byte *codes11          = m6809_codes11;
char **exg_tfr         = m6809_exg_tfr;
int  allow_6309_codes  = FALSE;
int  os9_patch         = FALSE;

unsigned index_string(char *buffer, unsigned pc);
unsigned index_string(char *buffer, unsigned pc)
{
  byte T;
  word W;
  char R;
  char buf[30];
  unsigned PC = pc;

  T = ARGBYTE(PC); PC++;
  R = reg[(T>>5)&0x03];

  if(T&0x80)
  {
    switch(T&0x1F)
    {
      case 0x00: sprintf(buf,",%c+",R);break;

      case 0x01: sprintf(buf,",%c++",R);break;

      case 0x02: sprintf(buf,",-%c",R);break;

      case 0x03: sprintf(buf,",--%c",R);break;

      case 0x04: sprintf(buf,",%c",R);break;

      case 0x05: sprintf(buf,"B,%c",R);break;

      case 0x06: sprintf(buf,"A,%c",R);break;

      case 0x08: T = ARGBYTE(PC); PC++;
                 sprintf(buf,"$%02X,%c",T,R);
                 break;

      case 0x09: W = ARGWORD(PC); PC+=2;
                 sprintf(buf,"$%04X,%c",W,R);
                 break;

      case 0x0B: sprintf(buf,"D,%c",R);break;

      case 0x0C: T = ARGBYTE(PC); PC++;
                 sprintf(buf,"$%02X,PC",T);
                 break;

      case 0x0D: W = ARGWORD(PC); PC+=2;
                 sprintf(buf,"$%04X,PC",W);
                 break;

      case 0x11: sprintf(buf,"[,%c++]",R);break;

      case 0x13: sprintf(buf,"[,--%c]",R);break;

      case 0x14: sprintf(buf,"[,%c]",R);break;

      case 0x15: sprintf(buf,"[B,%c]",R);break;

      case 0x16: sprintf(buf,"[A,%c]",R);break;

      case 0x18: T = ARGBYTE(PC); PC++;
                 sprintf(buf,"[$%02X,%c]",T,R);
                 break;

      case 0x19: W = ARGWORD(PC); PC+=2;
                 sprintf(buf,"[$%04X,%c]",W,R);
                 break;

      case 0x1B: sprintf(buf,"[D,%c]",R);break;

      case 0x1C: T = ARGBYTE(PC); PC++;
                 sprintf(buf,"[$%02X,PC]",T);
                 break;

      case 0x1D: W = ARGWORD(PC); PC+=2;
                 sprintf(buf,"[$%04X,PC]",W);
                 break;

      case 0x07: if(allow_6309_codes)
                 {
                   sprintf(buf,"E,%c",R);
                   break;
                 } else goto index_error;

      case 0x17: if(allow_6309_codes)
                 {
                   sprintf(buf,"[E,%c]",R);
                   break;
                 } else goto index_error;

      case 0x0A: if(allow_6309_codes)
                 {
                   sprintf(buf,"F,%c",R);
                   break;
                 } else goto index_error;

      case 0x1A: if(allow_6309_codes)
                 {
                   sprintf(buf,"[F,%c]",R);
                   break;
                 } else goto index_error;

      case 0x0E: if(allow_6309_codes)
                 {
                   sprintf(buf,"W,%c",R);
                   break;
                 } else goto index_error;

      case 0x1E: if(allow_6309_codes)
                 {
                   sprintf(buf,"[W,%c]",R);
                   break;
                 } else goto index_error;

      index_error: sprintf(buf,"???"); break;

      default:   if(T==0x9F)
                 {
                   W = ARGWORD(PC); PC+=2;
                   sprintf(buf,"[$%04X]",W);
                 }
                 else if(allow_6309_codes)
                 {
                   switch(T)
                   {
                     case 0x8F: sprintf(buf,",W");break;
                     case 0x90: sprintf(buf,"[,W]");break;

                     case 0xAF: W = ARGWORD(PC); PC+=2;
                                sprintf(buf,"$%04X,W",W);break;

                     case 0xB0: W = ARGWORD(PC); PC+=2;
                                sprintf(buf,"[$%04X,W]",W);break;

                     case 0xCF: sprintf(buf,",W++");break;

                     case 0xD0: sprintf(buf,"[,W++]");break;

                     case 0xEF: sprintf(buf,",--W");break;

                     case 0xF0: sprintf(buf,"[,--W]");break;

                     default:   sprintf(buf,"???"); break;
                   }
                 }
                 else sprintf(buf,"???");
                 break;
    }

  } else sprintf(buf,"%s,%c",off4[T&0x1F],R);

  strcat(buffer,buf);
  return(PC);
}

unsigned Dasm(char *buffer, unsigned pc, unsigned *pc_mode, unsigned *address);
unsigned Dasm(char *buffer, unsigned pc, unsigned *pc_mode, unsigned *address)
{
  byte T,M;
  word W,F;
  char *I;
  char buf[30];
  unsigned PC = pc;

  T = OPCODE(PC); PC++;

  if(T==0x10)
  {
    T = OPCODE(PC); PC++;
    W = (word)(T*3);
    T = codes10[W++];
    I = (char *)mne[T];
    M = codes10[W++];
    F = codes10[W];

    if( (T==_swi2) && (os9_patch==TRUE) )
    {
      T = OPCODE(PC); PC++;
      sprintf(buffer,"OS9 %s",os9_codes[T]);
      return(PC-pc);
    }

  }
  else if(T==0x11)
  {
    T = OPCODE(PC); PC++;
    W = (word)(T*3);
    T = codes11[W++];
    I = (char *)mne[T];
    M = codes11[W++];
    F = codes11[W];
  }
  else
  {
    W = (word)(T*3);
    T = codes[W++];
    I = (char *)mne[T];
    M = codes[W++];
    F = codes[W];
  }

  switch(M)
  {
    case _nom: sprintf(buffer,"Invalid");break;

    case _imp: sprintf(buffer,"%s", I);break;

    case _imb: T = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s #$%02X", I, T);
               *address = T;
               break;

    case _imw: W = ARGWORD(PC); PC+=2;
               sprintf(buffer,"%s #$%04X",I,W);
               *address = W;
               break;

    case _dir: T = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s <$%02X",I,T);
               *address = T;
               break;

    case _ext: W = ARGWORD(PC); PC+=2;
               sprintf(buffer,"%s $%04X",I,W);
               *address = W;
               break;

    case _ind: sprintf(buffer,"%s ",I);
               PC = index_string(buffer,PC);
               break;

    case _reb: T = ARGBYTE(PC); PC++;
               W = (word)(PC + (signed char)T);
               sprintf(buffer,"%s $%04X",I,W);
               *address = W;
               break;

    case _rew: W = ARGWORD(PC); PC+=2;
               W += (word)PC;
               sprintf(buffer,"%s $%04X",I,W);
               *address = W;
               break;

    case _r1:  T = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s %s,%s",I,exg_tfr[T>>4],exg_tfr[T&0xF]);
               break;

    case _r2:
    case _r3:  buf[0] = '\0';
               T = ARGBYTE(PC); PC++;
               if(T&0x80) strcat(buf,"PC,");
               if(T&0x40)
               {
                 if(M==_r2) strcat(buf,"U,");
                 if(M==_r3) strcat(buf,"S,");
               }
               if(T&0x20) strcat(buf,"Y,");
               if(T&0x10) strcat(buf,"X,");
               if(T&0x08) strcat(buf,"DP,");
               if(T&0x04) strcat(buf,"B,");
               if(T&0x02) strcat(buf,"A,");
               if(T&0x01) strcat(buf,"CC,");
               if(buf[0]!='\0') buf[strlen(buf)-1]='\0';
               sprintf(buffer,"%s %s",I,buf);
               break;

    case _bd:  M = ARGBYTE(PC); PC++;
               T = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s #$%02X,<$%02X",I,M,T);
               break;

    case _be:  T = ARGBYTE(PC); PC++;
               W = ARGWORD(PC); PC+=2;
               sprintf(buffer,"%s #$%02X,$%04X",I,T,W);
               *address = W;
               break;

    case _bt:  M = ARGBYTE(PC); PC++;
               T = ARGBYTE(PC); PC++;
#if 1
               sprintf(buffer,"%s %s.%01d,<$%02X.%01d",
               I,bit_r[M>>6],M&7,T,(M>>3)&7);
#else
               sprintf(buffer,"%s %s,%01d,%01d,$%02X",
               I,bit_r[M>>6],(M>>3)&7,M&7,T);
#endif
               break;

    case _t1:  T = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s %s+,%s+",I,block_r[T>>4],block_r[T&0xF]);
               break;

    case _t2:  T = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s %s-,%s-",I,block_r[T>>4],block_r[T&0xF]);
               break;

    case _t3:  T = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s %s+,%s",I,block_r[T>>4],block_r[T&0xF]);
               break;

    case _t4:  T = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s %s,%s+",I,block_r[T>>4],block_r[T&0xF]);
               break;

    case _iml: W = ARGWORD(PC); PC+=2;
               T = ARGBYTE(PC); PC++;
               M = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s #$%04X%02X%02X",I,W,T,M);
               break;

    case _bi:  T = ARGBYTE(PC); PC++;
               sprintf(buffer,"%s #$%02X,",I,T);
               PC = index_string(buffer,PC);
               break;

    default:   sprintf(buffer,"%s ERROR",I);

  }

  *pc_mode = F;
 
  return(PC-pc);
}

unsigned Dasm6809(char *buffer, unsigned pc, unsigned *pc_mode, unsigned *address)
{
  codes             = m6809_codes;
  codes10           = m6809_codes10;
  codes11           = m6809_codes11;
  exg_tfr           = m6809_exg_tfr;
  allow_6309_codes  = FALSE;

  return( Dasm(buffer, pc, pc_mode, address) );
}

unsigned Dasm6309(char *buffer, unsigned pc, unsigned *pc_mode, unsigned *address)
{
  codes             = h6309_codes;
  codes10           = h6309_codes10;
  codes11           = h6309_codes11;
  exg_tfr           = h6309_exg_tfr;
  allow_6309_codes  = TRUE;

  return( Dasm(buffer, pc, pc_mode, address) );
}
