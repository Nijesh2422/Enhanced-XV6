
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8d070713          	addi	a4,a4,-1840 # 80008920 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	efe78793          	addi	a5,a5,-258 # 80005f60 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbc6f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3b8080e7          	jalr	952(ra) # 800024e2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	164080e7          	jalr	356(ra) # 8000232c <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ea2080e7          	jalr	-350(ra) # 80002078 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	27a080e7          	jalr	634(ra) # 8000248c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	246080e7          	jalr	582(ra) # 80002538 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c96080e7          	jalr	-874(ra) # 800020dc <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	58078793          	addi	a5,a5,1408 # 800219f8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07aa23          	sw	zero,1492(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	36f72023          	sw	a5,864(a4) # 800088e0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	564dad83          	lw	s11,1380(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	50e50513          	addi	a0,a0,1294 # 80010b08 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3b050513          	addi	a0,a0,944 # 80010b08 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	39448493          	addi	s1,s1,916 # 80010b08 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	35450513          	addi	a0,a0,852 # 80010b28 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0e07a783          	lw	a5,224(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0b07b783          	ld	a5,176(a5) # 800088e8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0b073703          	ld	a4,176(a4) # 800088f0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2c6a0a13          	addi	s4,s4,710 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	07e48493          	addi	s1,s1,126 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	07e98993          	addi	s3,s3,126 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	848080e7          	jalr	-1976(ra) # 800020dc <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	25850513          	addi	a0,a0,600 # 80010b28 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0007a783          	lw	a5,0(a5) # 800088e0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	00673703          	ld	a4,6(a4) # 800088f0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	ff67b783          	ld	a5,-10(a5) # 800088e8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	22a98993          	addi	s3,s3,554 # 80010b28 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fe248493          	addi	s1,s1,-30 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fe290913          	addi	s2,s2,-30 # 800088f0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	75a080e7          	jalr	1882(ra) # 80002078 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1f448493          	addi	s1,s1,500 # 80010b28 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fae7b423          	sd	a4,-88(a5) # 800088f0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	16e48493          	addi	s1,s1,366 # 80010b28 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	19478793          	addi	a5,a5,404 # 80022b90 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	14490913          	addi	s2,s2,324 # 80010b60 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0a650513          	addi	a0,a0,166 # 80010b60 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	0c250513          	addi	a0,a0,194 # 80022b90 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	07048493          	addi	s1,s1,112 # 80010b60 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	05850513          	addi	a0,a0,88 # 80010b60 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	02c50513          	addi	a0,a0,44 # 80010b60 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc471>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a7070713          	addi	a4,a4,-1424 # 800088f8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	984080e7          	jalr	-1660(ra) # 80002842 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	0da080e7          	jalr	218(ra) # 80005fa0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	ff8080e7          	jalr	-8(ra) # 80001ec6 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	8e4080e7          	jalr	-1820(ra) # 8000281a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	904080e7          	jalr	-1788(ra) # 80002842 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	044080e7          	jalr	68(ra) # 80005f8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	052080e7          	jalr	82(ra) # 80005fa0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	1e2080e7          	jalr	482(ra) # 80003138 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	882080e7          	jalr	-1918(ra) # 800037e0 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	828080e7          	jalr	-2008(ra) # 8000478e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	13a080e7          	jalr	314(ra) # 800060a8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d32080e7          	jalr	-718(ra) # 80001ca8 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72a23          	sw	a5,-1676(a4) # 800088f8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9687b783          	ld	a5,-1688(a5) # 80008900 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc467>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6aa7b623          	sd	a0,1708(a5) # 80008900 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc470>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	76448493          	addi	s1,s1,1892 # 80010fb0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	f4aa0a13          	addi	s4,s4,-182 # 800177b0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8595                	srai	a1,a1,0x5
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1a048493          	addi	s1,s1,416
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	29850513          	addi	a0,a0,664 # 80010b80 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	29850513          	addi	a0,a0,664 # 80010b98 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6a048493          	addi	s1,s1,1696 # 80010fb0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	e7e98993          	addi	s3,s3,-386 # 800177b0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8795                	srai	a5,a5,0x5
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1a048493          	addi	s1,s1,416
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	21450513          	addi	a0,a0,532 # 80010bb0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1bc70713          	addi	a4,a4,444 # 80010b80 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e54080e7          	jalr	-428(ra) # 8000285a <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	d40080e7          	jalr	-704(ra) # 80003760 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	14a90913          	addi	s2,s2,330 # 80010b80 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3ee48493          	addi	s1,s1,1006 # 80010fb0 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	be690913          	addi	s2,s2,-1050 # 800177b0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	1a048493          	addi	s1,s1,416
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a89d                	j	80001c6a <allocproc+0xb4>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c525                	beqz	a0,80001c78 <allocproc+0xc2>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	c925                	beqz	a0,80001c90 <allocproc+0xda>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c46:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c4a:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	cc27a783          	lw	a5,-830(a5) # 80008910 <ticks>
    80001c56:	16f4a623          	sw	a5,364(s1)
  p->cur_ticks = 0;
    80001c5a:	1804a223          	sw	zero,388(s1)
  p->CurrentLevel = 0;
    80001c5e:	1804aa23          	sw	zero,404(s1)
  p->Waitticks = 0;
    80001c62:	1804ae23          	sw	zero,412(s1)
  p->TicksElapsed = 0;
    80001c66:	1804ac23          	sw	zero,408(s1)
}
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	60e2                	ld	ra,24(sp)
    80001c6e:	6442                	ld	s0,16(sp)
    80001c70:	64a2                	ld	s1,8(sp)
    80001c72:	6902                	ld	s2,0(sp)
    80001c74:	6105                	addi	sp,sp,32
    80001c76:	8082                	ret
    freeproc(p);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	ee4080e7          	jalr	-284(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	006080e7          	jalr	6(ra) # 80000c8a <release>
    return 0;
    80001c8c:	84ca                	mv	s1,s2
    80001c8e:	bff1                	j	80001c6a <allocproc+0xb4>
    freeproc(p);
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	ecc080e7          	jalr	-308(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	fee080e7          	jalr	-18(ra) # 80000c8a <release>
    return 0;
    80001ca4:	84ca                	mv	s1,s2
    80001ca6:	b7d1                	j	80001c6a <allocproc+0xb4>

0000000080001ca8 <userinit>:
{
    80001ca8:	1101                	addi	sp,sp,-32
    80001caa:	ec06                	sd	ra,24(sp)
    80001cac:	e822                	sd	s0,16(sp)
    80001cae:	e426                	sd	s1,8(sp)
    80001cb0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	f04080e7          	jalr	-252(ra) # 80001bb6 <allocproc>
    80001cba:	84aa                	mv	s1,a0
  initproc = p;
    80001cbc:	00007797          	auipc	a5,0x7
    80001cc0:	c4a7b623          	sd	a0,-948(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc4:	03400613          	li	a2,52
    80001cc8:	00007597          	auipc	a1,0x7
    80001ccc:	ba858593          	addi	a1,a1,-1112 # 80008870 <initcode>
    80001cd0:	6928                	ld	a0,80(a0)
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	684080e7          	jalr	1668(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cda:	6785                	lui	a5,0x1
    80001cdc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cde:	6cb8                	ld	a4,88(s1)
    80001ce0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ce4:	6cb8                	ld	a4,88(s1)
    80001ce6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce8:	4641                	li	a2,16
    80001cea:	00006597          	auipc	a1,0x6
    80001cee:	51658593          	addi	a1,a1,1302 # 80008200 <digits+0x1c0>
    80001cf2:	15848513          	addi	a0,s1,344
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	126080e7          	jalr	294(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cfe:	00006517          	auipc	a0,0x6
    80001d02:	51250513          	addi	a0,a0,1298 # 80008210 <digits+0x1d0>
    80001d06:	00002097          	auipc	ra,0x2
    80001d0a:	484080e7          	jalr	1156(ra) # 8000418a <namei>
    80001d0e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d12:	478d                	li	a5,3
    80001d14:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	f72080e7          	jalr	-142(ra) # 80000c8a <release>
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret

0000000080001d2a <growproc>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	e04a                	sd	s2,0(sp)
    80001d34:	1000                	addi	s0,sp,32
    80001d36:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	c74080e7          	jalr	-908(ra) # 800019ac <myproc>
    80001d40:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d42:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d44:	01204c63          	bgtz	s2,80001d5c <growproc+0x32>
  else if (n < 0)
    80001d48:	02094663          	bltz	s2,80001d74 <growproc+0x4a>
  p->sz = sz;
    80001d4c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d4e:	4501                	li	a0,0
}
    80001d50:	60e2                	ld	ra,24(sp)
    80001d52:	6442                	ld	s0,16(sp)
    80001d54:	64a2                	ld	s1,8(sp)
    80001d56:	6902                	ld	s2,0(sp)
    80001d58:	6105                	addi	sp,sp,32
    80001d5a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d5c:	4691                	li	a3,4
    80001d5e:	00b90633          	add	a2,s2,a1
    80001d62:	6928                	ld	a0,80(a0)
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	6ac080e7          	jalr	1708(ra) # 80001410 <uvmalloc>
    80001d6c:	85aa                	mv	a1,a0
    80001d6e:	fd79                	bnez	a0,80001d4c <growproc+0x22>
      return -1;
    80001d70:	557d                	li	a0,-1
    80001d72:	bff9                	j	80001d50 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d74:	00b90633          	add	a2,s2,a1
    80001d78:	6928                	ld	a0,80(a0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	64e080e7          	jalr	1614(ra) # 800013c8 <uvmdealloc>
    80001d82:	85aa                	mv	a1,a0
    80001d84:	b7e1                	j	80001d4c <growproc+0x22>

0000000080001d86 <fork>:
{
    80001d86:	7139                	addi	sp,sp,-64
    80001d88:	fc06                	sd	ra,56(sp)
    80001d8a:	f822                	sd	s0,48(sp)
    80001d8c:	f426                	sd	s1,40(sp)
    80001d8e:	f04a                	sd	s2,32(sp)
    80001d90:	ec4e                	sd	s3,24(sp)
    80001d92:	e852                	sd	s4,16(sp)
    80001d94:	e456                	sd	s5,8(sp)
    80001d96:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	c14080e7          	jalr	-1004(ra) # 800019ac <myproc>
    80001da0:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	e14080e7          	jalr	-492(ra) # 80001bb6 <allocproc>
    80001daa:	10050c63          	beqz	a0,80001ec2 <fork+0x13c>
    80001dae:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001db0:	048ab603          	ld	a2,72(s5)
    80001db4:	692c                	ld	a1,80(a0)
    80001db6:	050ab503          	ld	a0,80(s5)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	7ae080e7          	jalr	1966(ra) # 80001568 <uvmcopy>
    80001dc2:	04054863          	bltz	a0,80001e12 <fork+0x8c>
  np->sz = p->sz;
    80001dc6:	048ab783          	ld	a5,72(s5)
    80001dca:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dce:	058ab683          	ld	a3,88(s5)
    80001dd2:	87b6                	mv	a5,a3
    80001dd4:	058a3703          	ld	a4,88(s4)
    80001dd8:	12068693          	addi	a3,a3,288
    80001ddc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de0:	6788                	ld	a0,8(a5)
    80001de2:	6b8c                	ld	a1,16(a5)
    80001de4:	6f90                	ld	a2,24(a5)
    80001de6:	01073023          	sd	a6,0(a4)
    80001dea:	e708                	sd	a0,8(a4)
    80001dec:	eb0c                	sd	a1,16(a4)
    80001dee:	ef10                	sd	a2,24(a4)
    80001df0:	02078793          	addi	a5,a5,32
    80001df4:	02070713          	addi	a4,a4,32
    80001df8:	fed792e3          	bne	a5,a3,80001ddc <fork+0x56>
  np->trapframe->a0 = 0;
    80001dfc:	058a3783          	ld	a5,88(s4)
    80001e00:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e04:	0d0a8493          	addi	s1,s5,208
    80001e08:	0d0a0913          	addi	s2,s4,208
    80001e0c:	150a8993          	addi	s3,s5,336
    80001e10:	a00d                	j	80001e32 <fork+0xac>
    freeproc(np);
    80001e12:	8552                	mv	a0,s4
    80001e14:	00000097          	auipc	ra,0x0
    80001e18:	d4a080e7          	jalr	-694(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e1c:	8552                	mv	a0,s4
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	e6c080e7          	jalr	-404(ra) # 80000c8a <release>
    return -1;
    80001e26:	597d                	li	s2,-1
    80001e28:	a059                	j	80001eae <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e2a:	04a1                	addi	s1,s1,8
    80001e2c:	0921                	addi	s2,s2,8
    80001e2e:	01348b63          	beq	s1,s3,80001e44 <fork+0xbe>
    if (p->ofile[i])
    80001e32:	6088                	ld	a0,0(s1)
    80001e34:	d97d                	beqz	a0,80001e2a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e36:	00003097          	auipc	ra,0x3
    80001e3a:	9ea080e7          	jalr	-1558(ra) # 80004820 <filedup>
    80001e3e:	00a93023          	sd	a0,0(s2)
    80001e42:	b7e5                	j	80001e2a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e44:	150ab503          	ld	a0,336(s5)
    80001e48:	00002097          	auipc	ra,0x2
    80001e4c:	b58080e7          	jalr	-1192(ra) # 800039a0 <idup>
    80001e50:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e54:	4641                	li	a2,16
    80001e56:	158a8593          	addi	a1,s5,344
    80001e5a:	158a0513          	addi	a0,s4,344
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	fbe080e7          	jalr	-66(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e66:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e1e080e7          	jalr	-482(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e74:	0000f497          	auipc	s1,0xf
    80001e78:	d2448493          	addi	s1,s1,-732 # 80010b98 <wait_lock>
    80001e7c:	8526                	mv	a0,s1
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	d58080e7          	jalr	-680(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e86:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e8a:	8526                	mv	a0,s1
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	dfe080e7          	jalr	-514(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	d40080e7          	jalr	-704(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e9e:	478d                	li	a5,3
    80001ea0:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	de4080e7          	jalr	-540(ra) # 80000c8a <release>
}
    80001eae:	854a                	mv	a0,s2
    80001eb0:	70e2                	ld	ra,56(sp)
    80001eb2:	7442                	ld	s0,48(sp)
    80001eb4:	74a2                	ld	s1,40(sp)
    80001eb6:	7902                	ld	s2,32(sp)
    80001eb8:	69e2                	ld	s3,24(sp)
    80001eba:	6a42                	ld	s4,16(sp)
    80001ebc:	6aa2                	ld	s5,8(sp)
    80001ebe:	6121                	addi	sp,sp,64
    80001ec0:	8082                	ret
    return -1;
    80001ec2:	597d                	li	s2,-1
    80001ec4:	b7ed                	j	80001eae <fork+0x128>

0000000080001ec6 <scheduler>:
{
    80001ec6:	7139                	addi	sp,sp,-64
    80001ec8:	fc06                	sd	ra,56(sp)
    80001eca:	f822                	sd	s0,48(sp)
    80001ecc:	f426                	sd	s1,40(sp)
    80001ece:	f04a                	sd	s2,32(sp)
    80001ed0:	ec4e                	sd	s3,24(sp)
    80001ed2:	e852                	sd	s4,16(sp)
    80001ed4:	e456                	sd	s5,8(sp)
    80001ed6:	e05a                	sd	s6,0(sp)
    80001ed8:	0080                	addi	s0,sp,64
    80001eda:	8792                	mv	a5,tp
  int id = r_tp();
    80001edc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ede:	00779a93          	slli	s5,a5,0x7
    80001ee2:	0000f717          	auipc	a4,0xf
    80001ee6:	c9e70713          	addi	a4,a4,-866 # 80010b80 <pid_lock>
    80001eea:	9756                	add	a4,a4,s5
    80001eec:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ef0:	0000f717          	auipc	a4,0xf
    80001ef4:	cc870713          	addi	a4,a4,-824 # 80010bb8 <cpus+0x8>
    80001ef8:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001efa:	498d                	li	s3,3
        p->state = RUNNING;
    80001efc:	4b11                	li	s6,4
        c->proc = p;
    80001efe:	079e                	slli	a5,a5,0x7
    80001f00:	0000fa17          	auipc	s4,0xf
    80001f04:	c80a0a13          	addi	s4,s4,-896 # 80010b80 <pid_lock>
    80001f08:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f0a:	00016917          	auipc	s2,0x16
    80001f0e:	8a690913          	addi	s2,s2,-1882 # 800177b0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f12:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f16:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f1a:	10079073          	csrw	sstatus,a5
    80001f1e:	0000f497          	auipc	s1,0xf
    80001f22:	09248493          	addi	s1,s1,146 # 80010fb0 <proc>
    80001f26:	a811                	j	80001f3a <scheduler+0x74>
      release(&p->lock);
    80001f28:	8526                	mv	a0,s1
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	d60080e7          	jalr	-672(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f32:	1a048493          	addi	s1,s1,416
    80001f36:	fd248ee3          	beq	s1,s2,80001f12 <scheduler+0x4c>
      acquire(&p->lock);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	c9a080e7          	jalr	-870(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f44:	4c9c                	lw	a5,24(s1)
    80001f46:	ff3791e3          	bne	a5,s3,80001f28 <scheduler+0x62>
        p->state = RUNNING;
    80001f4a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f4e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f52:	06048593          	addi	a1,s1,96
    80001f56:	8556                	mv	a0,s5
    80001f58:	00001097          	auipc	ra,0x1
    80001f5c:	858080e7          	jalr	-1960(ra) # 800027b0 <swtch>
        c->proc = 0;
    80001f60:	020a3823          	sd	zero,48(s4)
    80001f64:	b7d1                	j	80001f28 <scheduler+0x62>

0000000080001f66 <sched>:
{
    80001f66:	7179                	addi	sp,sp,-48
    80001f68:	f406                	sd	ra,40(sp)
    80001f6a:	f022                	sd	s0,32(sp)
    80001f6c:	ec26                	sd	s1,24(sp)
    80001f6e:	e84a                	sd	s2,16(sp)
    80001f70:	e44e                	sd	s3,8(sp)
    80001f72:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f74:	00000097          	auipc	ra,0x0
    80001f78:	a38080e7          	jalr	-1480(ra) # 800019ac <myproc>
    80001f7c:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	bde080e7          	jalr	-1058(ra) # 80000b5c <holding>
    80001f86:	c93d                	beqz	a0,80001ffc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f88:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f8a:	2781                	sext.w	a5,a5
    80001f8c:	079e                	slli	a5,a5,0x7
    80001f8e:	0000f717          	auipc	a4,0xf
    80001f92:	bf270713          	addi	a4,a4,-1038 # 80010b80 <pid_lock>
    80001f96:	97ba                	add	a5,a5,a4
    80001f98:	0a87a703          	lw	a4,168(a5)
    80001f9c:	4785                	li	a5,1
    80001f9e:	06f71763          	bne	a4,a5,8000200c <sched+0xa6>
  if (p->state == RUNNING)
    80001fa2:	4c98                	lw	a4,24(s1)
    80001fa4:	4791                	li	a5,4
    80001fa6:	06f70b63          	beq	a4,a5,8000201c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001faa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fae:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fb0:	efb5                	bnez	a5,8000202c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fb4:	0000f917          	auipc	s2,0xf
    80001fb8:	bcc90913          	addi	s2,s2,-1076 # 80010b80 <pid_lock>
    80001fbc:	2781                	sext.w	a5,a5
    80001fbe:	079e                	slli	a5,a5,0x7
    80001fc0:	97ca                	add	a5,a5,s2
    80001fc2:	0ac7a983          	lw	s3,172(a5)
    80001fc6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fc8:	2781                	sext.w	a5,a5
    80001fca:	079e                	slli	a5,a5,0x7
    80001fcc:	0000f597          	auipc	a1,0xf
    80001fd0:	bec58593          	addi	a1,a1,-1044 # 80010bb8 <cpus+0x8>
    80001fd4:	95be                	add	a1,a1,a5
    80001fd6:	06048513          	addi	a0,s1,96
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	7d6080e7          	jalr	2006(ra) # 800027b0 <swtch>
    80001fe2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fe4:	2781                	sext.w	a5,a5
    80001fe6:	079e                	slli	a5,a5,0x7
    80001fe8:	993e                	add	s2,s2,a5
    80001fea:	0b392623          	sw	s3,172(s2)
}
    80001fee:	70a2                	ld	ra,40(sp)
    80001ff0:	7402                	ld	s0,32(sp)
    80001ff2:	64e2                	ld	s1,24(sp)
    80001ff4:	6942                	ld	s2,16(sp)
    80001ff6:	69a2                	ld	s3,8(sp)
    80001ff8:	6145                	addi	sp,sp,48
    80001ffa:	8082                	ret
    panic("sched p->lock");
    80001ffc:	00006517          	auipc	a0,0x6
    80002000:	21c50513          	addi	a0,a0,540 # 80008218 <digits+0x1d8>
    80002004:	ffffe097          	auipc	ra,0xffffe
    80002008:	53c080e7          	jalr	1340(ra) # 80000540 <panic>
    panic("sched locks");
    8000200c:	00006517          	auipc	a0,0x6
    80002010:	21c50513          	addi	a0,a0,540 # 80008228 <digits+0x1e8>
    80002014:	ffffe097          	auipc	ra,0xffffe
    80002018:	52c080e7          	jalr	1324(ra) # 80000540 <panic>
    panic("sched running");
    8000201c:	00006517          	auipc	a0,0x6
    80002020:	21c50513          	addi	a0,a0,540 # 80008238 <digits+0x1f8>
    80002024:	ffffe097          	auipc	ra,0xffffe
    80002028:	51c080e7          	jalr	1308(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000202c:	00006517          	auipc	a0,0x6
    80002030:	21c50513          	addi	a0,a0,540 # 80008248 <digits+0x208>
    80002034:	ffffe097          	auipc	ra,0xffffe
    80002038:	50c080e7          	jalr	1292(ra) # 80000540 <panic>

000000008000203c <yield>:
{
    8000203c:	1101                	addi	sp,sp,-32
    8000203e:	ec06                	sd	ra,24(sp)
    80002040:	e822                	sd	s0,16(sp)
    80002042:	e426                	sd	s1,8(sp)
    80002044:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002046:	00000097          	auipc	ra,0x0
    8000204a:	966080e7          	jalr	-1690(ra) # 800019ac <myproc>
    8000204e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	b86080e7          	jalr	-1146(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002058:	478d                	li	a5,3
    8000205a:	cc9c                	sw	a5,24(s1)
  sched();
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	f0a080e7          	jalr	-246(ra) # 80001f66 <sched>
  release(&p->lock);
    80002064:	8526                	mv	a0,s1
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	c24080e7          	jalr	-988(ra) # 80000c8a <release>
}
    8000206e:	60e2                	ld	ra,24(sp)
    80002070:	6442                	ld	s0,16(sp)
    80002072:	64a2                	ld	s1,8(sp)
    80002074:	6105                	addi	sp,sp,32
    80002076:	8082                	ret

0000000080002078 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002078:	7179                	addi	sp,sp,-48
    8000207a:	f406                	sd	ra,40(sp)
    8000207c:	f022                	sd	s0,32(sp)
    8000207e:	ec26                	sd	s1,24(sp)
    80002080:	e84a                	sd	s2,16(sp)
    80002082:	e44e                	sd	s3,8(sp)
    80002084:	1800                	addi	s0,sp,48
    80002086:	89aa                	mv	s3,a0
    80002088:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	922080e7          	jalr	-1758(ra) # 800019ac <myproc>
    80002092:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	b42080e7          	jalr	-1214(ra) # 80000bd6 <acquire>
  release(lk);
    8000209c:	854a                	mv	a0,s2
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	bec080e7          	jalr	-1044(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020a6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020aa:	4789                	li	a5,2
    800020ac:	cc9c                	sw	a5,24(s1)

  sched();
    800020ae:	00000097          	auipc	ra,0x0
    800020b2:	eb8080e7          	jalr	-328(ra) # 80001f66 <sched>

  // Tidy up.
  p->chan = 0;
    800020b6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ba:	8526                	mv	a0,s1
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	bce080e7          	jalr	-1074(ra) # 80000c8a <release>
  acquire(lk);
    800020c4:	854a                	mv	a0,s2
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	b10080e7          	jalr	-1264(ra) # 80000bd6 <acquire>
}
    800020ce:	70a2                	ld	ra,40(sp)
    800020d0:	7402                	ld	s0,32(sp)
    800020d2:	64e2                	ld	s1,24(sp)
    800020d4:	6942                	ld	s2,16(sp)
    800020d6:	69a2                	ld	s3,8(sp)
    800020d8:	6145                	addi	sp,sp,48
    800020da:	8082                	ret

00000000800020dc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020dc:	7139                	addi	sp,sp,-64
    800020de:	fc06                	sd	ra,56(sp)
    800020e0:	f822                	sd	s0,48(sp)
    800020e2:	f426                	sd	s1,40(sp)
    800020e4:	f04a                	sd	s2,32(sp)
    800020e6:	ec4e                	sd	s3,24(sp)
    800020e8:	e852                	sd	s4,16(sp)
    800020ea:	e456                	sd	s5,8(sp)
    800020ec:	0080                	addi	s0,sp,64
    800020ee:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020f0:	0000f497          	auipc	s1,0xf
    800020f4:	ec048493          	addi	s1,s1,-320 # 80010fb0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020f8:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020fa:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020fc:	00015917          	auipc	s2,0x15
    80002100:	6b490913          	addi	s2,s2,1716 # 800177b0 <tickslock>
    80002104:	a811                	j	80002118 <wakeup+0x3c>
      }
      release(&p->lock);
    80002106:	8526                	mv	a0,s1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	b82080e7          	jalr	-1150(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002110:	1a048493          	addi	s1,s1,416
    80002114:	03248663          	beq	s1,s2,80002140 <wakeup+0x64>
    if (p != myproc())
    80002118:	00000097          	auipc	ra,0x0
    8000211c:	894080e7          	jalr	-1900(ra) # 800019ac <myproc>
    80002120:	fea488e3          	beq	s1,a0,80002110 <wakeup+0x34>
      acquire(&p->lock);
    80002124:	8526                	mv	a0,s1
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	ab0080e7          	jalr	-1360(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000212e:	4c9c                	lw	a5,24(s1)
    80002130:	fd379be3          	bne	a5,s3,80002106 <wakeup+0x2a>
    80002134:	709c                	ld	a5,32(s1)
    80002136:	fd4798e3          	bne	a5,s4,80002106 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000213a:	0154ac23          	sw	s5,24(s1)
    8000213e:	b7e1                	j	80002106 <wakeup+0x2a>
    }
  }
}
    80002140:	70e2                	ld	ra,56(sp)
    80002142:	7442                	ld	s0,48(sp)
    80002144:	74a2                	ld	s1,40(sp)
    80002146:	7902                	ld	s2,32(sp)
    80002148:	69e2                	ld	s3,24(sp)
    8000214a:	6a42                	ld	s4,16(sp)
    8000214c:	6aa2                	ld	s5,8(sp)
    8000214e:	6121                	addi	sp,sp,64
    80002150:	8082                	ret

0000000080002152 <reparent>:
{
    80002152:	7179                	addi	sp,sp,-48
    80002154:	f406                	sd	ra,40(sp)
    80002156:	f022                	sd	s0,32(sp)
    80002158:	ec26                	sd	s1,24(sp)
    8000215a:	e84a                	sd	s2,16(sp)
    8000215c:	e44e                	sd	s3,8(sp)
    8000215e:	e052                	sd	s4,0(sp)
    80002160:	1800                	addi	s0,sp,48
    80002162:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002164:	0000f497          	auipc	s1,0xf
    80002168:	e4c48493          	addi	s1,s1,-436 # 80010fb0 <proc>
      pp->parent = initproc;
    8000216c:	00006a17          	auipc	s4,0x6
    80002170:	79ca0a13          	addi	s4,s4,1948 # 80008908 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002174:	00015997          	auipc	s3,0x15
    80002178:	63c98993          	addi	s3,s3,1596 # 800177b0 <tickslock>
    8000217c:	a029                	j	80002186 <reparent+0x34>
    8000217e:	1a048493          	addi	s1,s1,416
    80002182:	01348d63          	beq	s1,s3,8000219c <reparent+0x4a>
    if (pp->parent == p)
    80002186:	7c9c                	ld	a5,56(s1)
    80002188:	ff279be3          	bne	a5,s2,8000217e <reparent+0x2c>
      pp->parent = initproc;
    8000218c:	000a3503          	ld	a0,0(s4)
    80002190:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002192:	00000097          	auipc	ra,0x0
    80002196:	f4a080e7          	jalr	-182(ra) # 800020dc <wakeup>
    8000219a:	b7d5                	j	8000217e <reparent+0x2c>
}
    8000219c:	70a2                	ld	ra,40(sp)
    8000219e:	7402                	ld	s0,32(sp)
    800021a0:	64e2                	ld	s1,24(sp)
    800021a2:	6942                	ld	s2,16(sp)
    800021a4:	69a2                	ld	s3,8(sp)
    800021a6:	6a02                	ld	s4,0(sp)
    800021a8:	6145                	addi	sp,sp,48
    800021aa:	8082                	ret

00000000800021ac <exit>:
{
    800021ac:	7179                	addi	sp,sp,-48
    800021ae:	f406                	sd	ra,40(sp)
    800021b0:	f022                	sd	s0,32(sp)
    800021b2:	ec26                	sd	s1,24(sp)
    800021b4:	e84a                	sd	s2,16(sp)
    800021b6:	e44e                	sd	s3,8(sp)
    800021b8:	e052                	sd	s4,0(sp)
    800021ba:	1800                	addi	s0,sp,48
    800021bc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	7ee080e7          	jalr	2030(ra) # 800019ac <myproc>
    800021c6:	89aa                	mv	s3,a0
  if (p == initproc)
    800021c8:	00006797          	auipc	a5,0x6
    800021cc:	7407b783          	ld	a5,1856(a5) # 80008908 <initproc>
    800021d0:	0d050493          	addi	s1,a0,208
    800021d4:	15050913          	addi	s2,a0,336
    800021d8:	02a79363          	bne	a5,a0,800021fe <exit+0x52>
    panic("init exiting");
    800021dc:	00006517          	auipc	a0,0x6
    800021e0:	08450513          	addi	a0,a0,132 # 80008260 <digits+0x220>
    800021e4:	ffffe097          	auipc	ra,0xffffe
    800021e8:	35c080e7          	jalr	860(ra) # 80000540 <panic>
      fileclose(f);
    800021ec:	00002097          	auipc	ra,0x2
    800021f0:	686080e7          	jalr	1670(ra) # 80004872 <fileclose>
      p->ofile[fd] = 0;
    800021f4:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021f8:	04a1                	addi	s1,s1,8
    800021fa:	01248563          	beq	s1,s2,80002204 <exit+0x58>
    if (p->ofile[fd])
    800021fe:	6088                	ld	a0,0(s1)
    80002200:	f575                	bnez	a0,800021ec <exit+0x40>
    80002202:	bfdd                	j	800021f8 <exit+0x4c>
  begin_op();
    80002204:	00002097          	auipc	ra,0x2
    80002208:	1a6080e7          	jalr	422(ra) # 800043aa <begin_op>
  iput(p->cwd);
    8000220c:	1509b503          	ld	a0,336(s3)
    80002210:	00002097          	auipc	ra,0x2
    80002214:	988080e7          	jalr	-1656(ra) # 80003b98 <iput>
  end_op();
    80002218:	00002097          	auipc	ra,0x2
    8000221c:	210080e7          	jalr	528(ra) # 80004428 <end_op>
  p->cwd = 0;
    80002220:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002224:	0000f497          	auipc	s1,0xf
    80002228:	97448493          	addi	s1,s1,-1676 # 80010b98 <wait_lock>
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	9a8080e7          	jalr	-1624(ra) # 80000bd6 <acquire>
  reparent(p);
    80002236:	854e                	mv	a0,s3
    80002238:	00000097          	auipc	ra,0x0
    8000223c:	f1a080e7          	jalr	-230(ra) # 80002152 <reparent>
  wakeup(p->parent);
    80002240:	0389b503          	ld	a0,56(s3)
    80002244:	00000097          	auipc	ra,0x0
    80002248:	e98080e7          	jalr	-360(ra) # 800020dc <wakeup>
  acquire(&p->lock);
    8000224c:	854e                	mv	a0,s3
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	988080e7          	jalr	-1656(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002256:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000225a:	4795                	li	a5,5
    8000225c:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002260:	00006797          	auipc	a5,0x6
    80002264:	6b07a783          	lw	a5,1712(a5) # 80008910 <ticks>
    80002268:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	a1c080e7          	jalr	-1508(ra) # 80000c8a <release>
  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	cf0080e7          	jalr	-784(ra) # 80001f66 <sched>
  panic("zombie exit");
    8000227e:	00006517          	auipc	a0,0x6
    80002282:	ff250513          	addi	a0,a0,-14 # 80008270 <digits+0x230>
    80002286:	ffffe097          	auipc	ra,0xffffe
    8000228a:	2ba080e7          	jalr	698(ra) # 80000540 <panic>

000000008000228e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000228e:	7179                	addi	sp,sp,-48
    80002290:	f406                	sd	ra,40(sp)
    80002292:	f022                	sd	s0,32(sp)
    80002294:	ec26                	sd	s1,24(sp)
    80002296:	e84a                	sd	s2,16(sp)
    80002298:	e44e                	sd	s3,8(sp)
    8000229a:	1800                	addi	s0,sp,48
    8000229c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000229e:	0000f497          	auipc	s1,0xf
    800022a2:	d1248493          	addi	s1,s1,-750 # 80010fb0 <proc>
    800022a6:	00015997          	auipc	s3,0x15
    800022aa:	50a98993          	addi	s3,s3,1290 # 800177b0 <tickslock>
  {
    acquire(&p->lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	926080e7          	jalr	-1754(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022b8:	589c                	lw	a5,48(s1)
    800022ba:	01278d63          	beq	a5,s2,800022d4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022be:	8526                	mv	a0,s1
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	9ca080e7          	jalr	-1590(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022c8:	1a048493          	addi	s1,s1,416
    800022cc:	ff3491e3          	bne	s1,s3,800022ae <kill+0x20>
  }
  return -1;
    800022d0:	557d                	li	a0,-1
    800022d2:	a829                	j	800022ec <kill+0x5e>
      p->killed = 1;
    800022d4:	4785                	li	a5,1
    800022d6:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022d8:	4c98                	lw	a4,24(s1)
    800022da:	4789                	li	a5,2
    800022dc:	00f70f63          	beq	a4,a5,800022fa <kill+0x6c>
      release(&p->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9a8080e7          	jalr	-1624(ra) # 80000c8a <release>
      return 0;
    800022ea:	4501                	li	a0,0
}
    800022ec:	70a2                	ld	ra,40(sp)
    800022ee:	7402                	ld	s0,32(sp)
    800022f0:	64e2                	ld	s1,24(sp)
    800022f2:	6942                	ld	s2,16(sp)
    800022f4:	69a2                	ld	s3,8(sp)
    800022f6:	6145                	addi	sp,sp,48
    800022f8:	8082                	ret
        p->state = RUNNABLE;
    800022fa:	478d                	li	a5,3
    800022fc:	cc9c                	sw	a5,24(s1)
    800022fe:	b7cd                	j	800022e0 <kill+0x52>

0000000080002300 <setkilled>:

void setkilled(struct proc *p)
{
    80002300:	1101                	addi	sp,sp,-32
    80002302:	ec06                	sd	ra,24(sp)
    80002304:	e822                	sd	s0,16(sp)
    80002306:	e426                	sd	s1,8(sp)
    80002308:	1000                	addi	s0,sp,32
    8000230a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	8ca080e7          	jalr	-1846(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002314:	4785                	li	a5,1
    80002316:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002318:	8526                	mv	a0,s1
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	970080e7          	jalr	-1680(ra) # 80000c8a <release>
}
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6105                	addi	sp,sp,32
    8000232a:	8082                	ret

000000008000232c <killed>:

int killed(struct proc *p)
{
    8000232c:	1101                	addi	sp,sp,-32
    8000232e:	ec06                	sd	ra,24(sp)
    80002330:	e822                	sd	s0,16(sp)
    80002332:	e426                	sd	s1,8(sp)
    80002334:	e04a                	sd	s2,0(sp)
    80002336:	1000                	addi	s0,sp,32
    80002338:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	89c080e7          	jalr	-1892(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002342:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	942080e7          	jalr	-1726(ra) # 80000c8a <release>
  return k;
}
    80002350:	854a                	mv	a0,s2
    80002352:	60e2                	ld	ra,24(sp)
    80002354:	6442                	ld	s0,16(sp)
    80002356:	64a2                	ld	s1,8(sp)
    80002358:	6902                	ld	s2,0(sp)
    8000235a:	6105                	addi	sp,sp,32
    8000235c:	8082                	ret

000000008000235e <wait>:
{
    8000235e:	715d                	addi	sp,sp,-80
    80002360:	e486                	sd	ra,72(sp)
    80002362:	e0a2                	sd	s0,64(sp)
    80002364:	fc26                	sd	s1,56(sp)
    80002366:	f84a                	sd	s2,48(sp)
    80002368:	f44e                	sd	s3,40(sp)
    8000236a:	f052                	sd	s4,32(sp)
    8000236c:	ec56                	sd	s5,24(sp)
    8000236e:	e85a                	sd	s6,16(sp)
    80002370:	e45e                	sd	s7,8(sp)
    80002372:	e062                	sd	s8,0(sp)
    80002374:	0880                	addi	s0,sp,80
    80002376:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	634080e7          	jalr	1588(ra) # 800019ac <myproc>
    80002380:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002382:	0000f517          	auipc	a0,0xf
    80002386:	81650513          	addi	a0,a0,-2026 # 80010b98 <wait_lock>
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	84c080e7          	jalr	-1972(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002392:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002394:	4a15                	li	s4,5
        havekids = 1;
    80002396:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002398:	00015997          	auipc	s3,0x15
    8000239c:	41898993          	addi	s3,s3,1048 # 800177b0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800023a0:	0000ec17          	auipc	s8,0xe
    800023a4:	7f8c0c13          	addi	s8,s8,2040 # 80010b98 <wait_lock>
    havekids = 0;
    800023a8:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023aa:	0000f497          	auipc	s1,0xf
    800023ae:	c0648493          	addi	s1,s1,-1018 # 80010fb0 <proc>
    800023b2:	a0bd                	j	80002420 <wait+0xc2>
          pid = pp->pid;
    800023b4:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023b8:	000b0e63          	beqz	s6,800023d4 <wait+0x76>
    800023bc:	4691                	li	a3,4
    800023be:	02c48613          	addi	a2,s1,44
    800023c2:	85da                	mv	a1,s6
    800023c4:	05093503          	ld	a0,80(s2)
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	2a4080e7          	jalr	676(ra) # 8000166c <copyout>
    800023d0:	02054563          	bltz	a0,800023fa <wait+0x9c>
          freeproc(pp);
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	788080e7          	jalr	1928(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
          release(&wait_lock);
    800023e8:	0000e517          	auipc	a0,0xe
    800023ec:	7b050513          	addi	a0,a0,1968 # 80010b98 <wait_lock>
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	89a080e7          	jalr	-1894(ra) # 80000c8a <release>
          return pid;
    800023f8:	a0b5                	j	80002464 <wait+0x106>
            release(&pp->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	88e080e7          	jalr	-1906(ra) # 80000c8a <release>
            release(&wait_lock);
    80002404:	0000e517          	auipc	a0,0xe
    80002408:	79450513          	addi	a0,a0,1940 # 80010b98 <wait_lock>
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	87e080e7          	jalr	-1922(ra) # 80000c8a <release>
            return -1;
    80002414:	59fd                	li	s3,-1
    80002416:	a0b9                	j	80002464 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002418:	1a048493          	addi	s1,s1,416
    8000241c:	03348463          	beq	s1,s3,80002444 <wait+0xe6>
      if (pp->parent == p)
    80002420:	7c9c                	ld	a5,56(s1)
    80002422:	ff279be3          	bne	a5,s2,80002418 <wait+0xba>
        acquire(&pp->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	7ae080e7          	jalr	1966(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002430:	4c9c                	lw	a5,24(s1)
    80002432:	f94781e3          	beq	a5,s4,800023b4 <wait+0x56>
        release(&pp->lock);
    80002436:	8526                	mv	a0,s1
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	852080e7          	jalr	-1966(ra) # 80000c8a <release>
        havekids = 1;
    80002440:	8756                	mv	a4,s5
    80002442:	bfd9                	j	80002418 <wait+0xba>
    if (!havekids || killed(p))
    80002444:	c719                	beqz	a4,80002452 <wait+0xf4>
    80002446:	854a                	mv	a0,s2
    80002448:	00000097          	auipc	ra,0x0
    8000244c:	ee4080e7          	jalr	-284(ra) # 8000232c <killed>
    80002450:	c51d                	beqz	a0,8000247e <wait+0x120>
      release(&wait_lock);
    80002452:	0000e517          	auipc	a0,0xe
    80002456:	74650513          	addi	a0,a0,1862 # 80010b98 <wait_lock>
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	830080e7          	jalr	-2000(ra) # 80000c8a <release>
      return -1;
    80002462:	59fd                	li	s3,-1
}
    80002464:	854e                	mv	a0,s3
    80002466:	60a6                	ld	ra,72(sp)
    80002468:	6406                	ld	s0,64(sp)
    8000246a:	74e2                	ld	s1,56(sp)
    8000246c:	7942                	ld	s2,48(sp)
    8000246e:	79a2                	ld	s3,40(sp)
    80002470:	7a02                	ld	s4,32(sp)
    80002472:	6ae2                	ld	s5,24(sp)
    80002474:	6b42                	ld	s6,16(sp)
    80002476:	6ba2                	ld	s7,8(sp)
    80002478:	6c02                	ld	s8,0(sp)
    8000247a:	6161                	addi	sp,sp,80
    8000247c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000247e:	85e2                	mv	a1,s8
    80002480:	854a                	mv	a0,s2
    80002482:	00000097          	auipc	ra,0x0
    80002486:	bf6080e7          	jalr	-1034(ra) # 80002078 <sleep>
    havekids = 0;
    8000248a:	bf39                	j	800023a8 <wait+0x4a>

000000008000248c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000248c:	7179                	addi	sp,sp,-48
    8000248e:	f406                	sd	ra,40(sp)
    80002490:	f022                	sd	s0,32(sp)
    80002492:	ec26                	sd	s1,24(sp)
    80002494:	e84a                	sd	s2,16(sp)
    80002496:	e44e                	sd	s3,8(sp)
    80002498:	e052                	sd	s4,0(sp)
    8000249a:	1800                	addi	s0,sp,48
    8000249c:	84aa                	mv	s1,a0
    8000249e:	892e                	mv	s2,a1
    800024a0:	89b2                	mv	s3,a2
    800024a2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	508080e7          	jalr	1288(ra) # 800019ac <myproc>
  if (user_dst)
    800024ac:	c08d                	beqz	s1,800024ce <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800024ae:	86d2                	mv	a3,s4
    800024b0:	864e                	mv	a2,s3
    800024b2:	85ca                	mv	a1,s2
    800024b4:	6928                	ld	a0,80(a0)
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	1b6080e7          	jalr	438(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024be:	70a2                	ld	ra,40(sp)
    800024c0:	7402                	ld	s0,32(sp)
    800024c2:	64e2                	ld	s1,24(sp)
    800024c4:	6942                	ld	s2,16(sp)
    800024c6:	69a2                	ld	s3,8(sp)
    800024c8:	6a02                	ld	s4,0(sp)
    800024ca:	6145                	addi	sp,sp,48
    800024cc:	8082                	ret
    memmove((char *)dst, src, len);
    800024ce:	000a061b          	sext.w	a2,s4
    800024d2:	85ce                	mv	a1,s3
    800024d4:	854a                	mv	a0,s2
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	858080e7          	jalr	-1960(ra) # 80000d2e <memmove>
    return 0;
    800024de:	8526                	mv	a0,s1
    800024e0:	bff9                	j	800024be <either_copyout+0x32>

00000000800024e2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024e2:	7179                	addi	sp,sp,-48
    800024e4:	f406                	sd	ra,40(sp)
    800024e6:	f022                	sd	s0,32(sp)
    800024e8:	ec26                	sd	s1,24(sp)
    800024ea:	e84a                	sd	s2,16(sp)
    800024ec:	e44e                	sd	s3,8(sp)
    800024ee:	e052                	sd	s4,0(sp)
    800024f0:	1800                	addi	s0,sp,48
    800024f2:	892a                	mv	s2,a0
    800024f4:	84ae                	mv	s1,a1
    800024f6:	89b2                	mv	s3,a2
    800024f8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	4b2080e7          	jalr	1202(ra) # 800019ac <myproc>
  if (user_src)
    80002502:	c08d                	beqz	s1,80002524 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002504:	86d2                	mv	a3,s4
    80002506:	864e                	mv	a2,s3
    80002508:	85ca                	mv	a1,s2
    8000250a:	6928                	ld	a0,80(a0)
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	1ec080e7          	jalr	492(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002514:	70a2                	ld	ra,40(sp)
    80002516:	7402                	ld	s0,32(sp)
    80002518:	64e2                	ld	s1,24(sp)
    8000251a:	6942                	ld	s2,16(sp)
    8000251c:	69a2                	ld	s3,8(sp)
    8000251e:	6a02                	ld	s4,0(sp)
    80002520:	6145                	addi	sp,sp,48
    80002522:	8082                	ret
    memmove(dst, (char *)src, len);
    80002524:	000a061b          	sext.w	a2,s4
    80002528:	85ce                	mv	a1,s3
    8000252a:	854a                	mv	a0,s2
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	802080e7          	jalr	-2046(ra) # 80000d2e <memmove>
    return 0;
    80002534:	8526                	mv	a0,s1
    80002536:	bff9                	j	80002514 <either_copyin+0x32>

0000000080002538 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002538:	715d                	addi	sp,sp,-80
    8000253a:	e486                	sd	ra,72(sp)
    8000253c:	e0a2                	sd	s0,64(sp)
    8000253e:	fc26                	sd	s1,56(sp)
    80002540:	f84a                	sd	s2,48(sp)
    80002542:	f44e                	sd	s3,40(sp)
    80002544:	f052                	sd	s4,32(sp)
    80002546:	ec56                	sd	s5,24(sp)
    80002548:	e85a                	sd	s6,16(sp)
    8000254a:	e45e                	sd	s7,8(sp)
    8000254c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000254e:	00006517          	auipc	a0,0x6
    80002552:	b7a50513          	addi	a0,a0,-1158 # 800080c8 <digits+0x88>
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	034080e7          	jalr	52(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000255e:	0000f497          	auipc	s1,0xf
    80002562:	baa48493          	addi	s1,s1,-1110 # 80011108 <proc+0x158>
    80002566:	00015917          	auipc	s2,0x15
    8000256a:	3a290913          	addi	s2,s2,930 # 80017908 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002570:	00006997          	auipc	s3,0x6
    80002574:	d1098993          	addi	s3,s3,-752 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002578:	00006a97          	auipc	s5,0x6
    8000257c:	d10a8a93          	addi	s5,s5,-752 # 80008288 <digits+0x248>
    printf("\n");
    80002580:	00006a17          	auipc	s4,0x6
    80002584:	b48a0a13          	addi	s4,s4,-1208 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002588:	00006b97          	auipc	s7,0x6
    8000258c:	d40b8b93          	addi	s7,s7,-704 # 800082c8 <states.0>
    80002590:	a00d                	j	800025b2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002592:	ed86a583          	lw	a1,-296(a3)
    80002596:	8556                	mv	a0,s5
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	ff2080e7          	jalr	-14(ra) # 8000058a <printf>
    printf("\n");
    800025a0:	8552                	mv	a0,s4
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	fe8080e7          	jalr	-24(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025aa:	1a048493          	addi	s1,s1,416
    800025ae:	03248263          	beq	s1,s2,800025d2 <procdump+0x9a>
    if (p->state == UNUSED)
    800025b2:	86a6                	mv	a3,s1
    800025b4:	ec04a783          	lw	a5,-320(s1)
    800025b8:	dbed                	beqz	a5,800025aa <procdump+0x72>
      state = "???";
    800025ba:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025bc:	fcfb6be3          	bltu	s6,a5,80002592 <procdump+0x5a>
    800025c0:	02079713          	slli	a4,a5,0x20
    800025c4:	01d75793          	srli	a5,a4,0x1d
    800025c8:	97de                	add	a5,a5,s7
    800025ca:	6390                	ld	a2,0(a5)
    800025cc:	f279                	bnez	a2,80002592 <procdump+0x5a>
      state = "???";
    800025ce:	864e                	mv	a2,s3
    800025d0:	b7c9                	j	80002592 <procdump+0x5a>
  }
}
    800025d2:	60a6                	ld	ra,72(sp)
    800025d4:	6406                	ld	s0,64(sp)
    800025d6:	74e2                	ld	s1,56(sp)
    800025d8:	7942                	ld	s2,48(sp)
    800025da:	79a2                	ld	s3,40(sp)
    800025dc:	7a02                	ld	s4,32(sp)
    800025de:	6ae2                	ld	s5,24(sp)
    800025e0:	6b42                	ld	s6,16(sp)
    800025e2:	6ba2                	ld	s7,8(sp)
    800025e4:	6161                	addi	sp,sp,80
    800025e6:	8082                	ret

00000000800025e8 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800025e8:	711d                	addi	sp,sp,-96
    800025ea:	ec86                	sd	ra,88(sp)
    800025ec:	e8a2                	sd	s0,80(sp)
    800025ee:	e4a6                	sd	s1,72(sp)
    800025f0:	e0ca                	sd	s2,64(sp)
    800025f2:	fc4e                	sd	s3,56(sp)
    800025f4:	f852                	sd	s4,48(sp)
    800025f6:	f456                	sd	s5,40(sp)
    800025f8:	f05a                	sd	s6,32(sp)
    800025fa:	ec5e                	sd	s7,24(sp)
    800025fc:	e862                	sd	s8,16(sp)
    800025fe:	e466                	sd	s9,8(sp)
    80002600:	e06a                	sd	s10,0(sp)
    80002602:	1080                	addi	s0,sp,96
    80002604:	8b2a                	mv	s6,a0
    80002606:	8bae                	mv	s7,a1
    80002608:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	3a2080e7          	jalr	930(ra) # 800019ac <myproc>
    80002612:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002614:	0000e517          	auipc	a0,0xe
    80002618:	58450513          	addi	a0,a0,1412 # 80010b98 <wait_lock>
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	5ba080e7          	jalr	1466(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002624:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002626:	4a15                	li	s4,5
        havekids = 1;
    80002628:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000262a:	00015997          	auipc	s3,0x15
    8000262e:	18698993          	addi	s3,s3,390 # 800177b0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002632:	0000ed17          	auipc	s10,0xe
    80002636:	566d0d13          	addi	s10,s10,1382 # 80010b98 <wait_lock>
    havekids = 0;
    8000263a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000263c:	0000f497          	auipc	s1,0xf
    80002640:	97448493          	addi	s1,s1,-1676 # 80010fb0 <proc>
    80002644:	a059                	j	800026ca <waitx+0xe2>
          pid = np->pid;
    80002646:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000264a:	1684a783          	lw	a5,360(s1)
    8000264e:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002652:	16c4a703          	lw	a4,364(s1)
    80002656:	9f3d                	addw	a4,a4,a5
    80002658:	1704a783          	lw	a5,368(s1)
    8000265c:	9f99                	subw	a5,a5,a4
    8000265e:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002662:	000b0e63          	beqz	s6,8000267e <waitx+0x96>
    80002666:	4691                	li	a3,4
    80002668:	02c48613          	addi	a2,s1,44
    8000266c:	85da                	mv	a1,s6
    8000266e:	05093503          	ld	a0,80(s2)
    80002672:	fffff097          	auipc	ra,0xfffff
    80002676:	ffa080e7          	jalr	-6(ra) # 8000166c <copyout>
    8000267a:	02054563          	bltz	a0,800026a4 <waitx+0xbc>
          freeproc(np);
    8000267e:	8526                	mv	a0,s1
    80002680:	fffff097          	auipc	ra,0xfffff
    80002684:	4de080e7          	jalr	1246(ra) # 80001b5e <freeproc>
          release(&np->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	600080e7          	jalr	1536(ra) # 80000c8a <release>
          release(&wait_lock);
    80002692:	0000e517          	auipc	a0,0xe
    80002696:	50650513          	addi	a0,a0,1286 # 80010b98 <wait_lock>
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	5f0080e7          	jalr	1520(ra) # 80000c8a <release>
          return pid;
    800026a2:	a09d                	j	80002708 <waitx+0x120>
            release(&np->lock);
    800026a4:	8526                	mv	a0,s1
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	5e4080e7          	jalr	1508(ra) # 80000c8a <release>
            release(&wait_lock);
    800026ae:	0000e517          	auipc	a0,0xe
    800026b2:	4ea50513          	addi	a0,a0,1258 # 80010b98 <wait_lock>
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	5d4080e7          	jalr	1492(ra) # 80000c8a <release>
            return -1;
    800026be:	59fd                	li	s3,-1
    800026c0:	a0a1                	j	80002708 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800026c2:	1a048493          	addi	s1,s1,416
    800026c6:	03348463          	beq	s1,s3,800026ee <waitx+0x106>
      if (np->parent == p)
    800026ca:	7c9c                	ld	a5,56(s1)
    800026cc:	ff279be3          	bne	a5,s2,800026c2 <waitx+0xda>
        acquire(&np->lock);
    800026d0:	8526                	mv	a0,s1
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	504080e7          	jalr	1284(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800026da:	4c9c                	lw	a5,24(s1)
    800026dc:	f74785e3          	beq	a5,s4,80002646 <waitx+0x5e>
        release(&np->lock);
    800026e0:	8526                	mv	a0,s1
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	5a8080e7          	jalr	1448(ra) # 80000c8a <release>
        havekids = 1;
    800026ea:	8756                	mv	a4,s5
    800026ec:	bfd9                	j	800026c2 <waitx+0xda>
    if (!havekids || p->killed)
    800026ee:	c701                	beqz	a4,800026f6 <waitx+0x10e>
    800026f0:	02892783          	lw	a5,40(s2)
    800026f4:	cb8d                	beqz	a5,80002726 <waitx+0x13e>
      release(&wait_lock);
    800026f6:	0000e517          	auipc	a0,0xe
    800026fa:	4a250513          	addi	a0,a0,1186 # 80010b98 <wait_lock>
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	58c080e7          	jalr	1420(ra) # 80000c8a <release>
      return -1;
    80002706:	59fd                	li	s3,-1
  }
}
    80002708:	854e                	mv	a0,s3
    8000270a:	60e6                	ld	ra,88(sp)
    8000270c:	6446                	ld	s0,80(sp)
    8000270e:	64a6                	ld	s1,72(sp)
    80002710:	6906                	ld	s2,64(sp)
    80002712:	79e2                	ld	s3,56(sp)
    80002714:	7a42                	ld	s4,48(sp)
    80002716:	7aa2                	ld	s5,40(sp)
    80002718:	7b02                	ld	s6,32(sp)
    8000271a:	6be2                	ld	s7,24(sp)
    8000271c:	6c42                	ld	s8,16(sp)
    8000271e:	6ca2                	ld	s9,8(sp)
    80002720:	6d02                	ld	s10,0(sp)
    80002722:	6125                	addi	sp,sp,96
    80002724:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002726:	85ea                	mv	a1,s10
    80002728:	854a                	mv	a0,s2
    8000272a:	00000097          	auipc	ra,0x0
    8000272e:	94e080e7          	jalr	-1714(ra) # 80002078 <sleep>
    havekids = 0;
    80002732:	b721                	j	8000263a <waitx+0x52>

0000000080002734 <update_time>:

void update_time()
{
    80002734:	7179                	addi	sp,sp,-48
    80002736:	f406                	sd	ra,40(sp)
    80002738:	f022                	sd	s0,32(sp)
    8000273a:	ec26                	sd	s1,24(sp)
    8000273c:	e84a                	sd	s2,16(sp)
    8000273e:	e44e                	sd	s3,8(sp)
    80002740:	e052                	sd	s4,0(sp)
    80002742:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002744:	0000f497          	auipc	s1,0xf
    80002748:	86c48493          	addi	s1,s1,-1940 # 80010fb0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000274c:	4991                	li	s3,4
    {
      p->TicksElapsed++;
      p->rtime++;
    }
    else if (p->state == RUNNABLE)
    8000274e:	4a0d                	li	s4,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002750:	00015917          	auipc	s2,0x15
    80002754:	06090913          	addi	s2,s2,96 # 800177b0 <tickslock>
    80002758:	a025                	j	80002780 <update_time+0x4c>
      p->TicksElapsed++;
    8000275a:	1984a783          	lw	a5,408(s1)
    8000275e:	2785                	addiw	a5,a5,1
    80002760:	18f4ac23          	sw	a5,408(s1)
      p->rtime++;
    80002764:	1684a783          	lw	a5,360(s1)
    80002768:	2785                	addiw	a5,a5,1
    8000276a:	16f4a423          	sw	a5,360(s1)
    //   if (p->pid <= 13 && p->pid >= 9)
    //   {
    //     printf("(%d,%d,%d),\n", p->pid, p->CurrentLevel, ticks);
    //   }
    // }
    release(&p->lock);
    8000276e:	8526                	mv	a0,s1
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	51a080e7          	jalr	1306(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002778:	1a048493          	addi	s1,s1,416
    8000277c:	03248263          	beq	s1,s2,800027a0 <update_time+0x6c>
    acquire(&p->lock);
    80002780:	8526                	mv	a0,s1
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	454080e7          	jalr	1108(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    8000278a:	4c9c                	lw	a5,24(s1)
    8000278c:	fd3787e3          	beq	a5,s3,8000275a <update_time+0x26>
    else if (p->state == RUNNABLE)
    80002790:	fd479fe3          	bne	a5,s4,8000276e <update_time+0x3a>
      p->Waitticks++;
    80002794:	19c4a783          	lw	a5,412(s1)
    80002798:	2785                	addiw	a5,a5,1
    8000279a:	18f4ae23          	sw	a5,412(s1)
    8000279e:	bfc1                	j	8000276e <update_time+0x3a>
  }
    800027a0:	70a2                	ld	ra,40(sp)
    800027a2:	7402                	ld	s0,32(sp)
    800027a4:	64e2                	ld	s1,24(sp)
    800027a6:	6942                	ld	s2,16(sp)
    800027a8:	69a2                	ld	s3,8(sp)
    800027aa:	6a02                	ld	s4,0(sp)
    800027ac:	6145                	addi	sp,sp,48
    800027ae:	8082                	ret

00000000800027b0 <swtch>:
    800027b0:	00153023          	sd	ra,0(a0)
    800027b4:	00253423          	sd	sp,8(a0)
    800027b8:	e900                	sd	s0,16(a0)
    800027ba:	ed04                	sd	s1,24(a0)
    800027bc:	03253023          	sd	s2,32(a0)
    800027c0:	03353423          	sd	s3,40(a0)
    800027c4:	03453823          	sd	s4,48(a0)
    800027c8:	03553c23          	sd	s5,56(a0)
    800027cc:	05653023          	sd	s6,64(a0)
    800027d0:	05753423          	sd	s7,72(a0)
    800027d4:	05853823          	sd	s8,80(a0)
    800027d8:	05953c23          	sd	s9,88(a0)
    800027dc:	07a53023          	sd	s10,96(a0)
    800027e0:	07b53423          	sd	s11,104(a0)
    800027e4:	0005b083          	ld	ra,0(a1)
    800027e8:	0085b103          	ld	sp,8(a1)
    800027ec:	6980                	ld	s0,16(a1)
    800027ee:	6d84                	ld	s1,24(a1)
    800027f0:	0205b903          	ld	s2,32(a1)
    800027f4:	0285b983          	ld	s3,40(a1)
    800027f8:	0305ba03          	ld	s4,48(a1)
    800027fc:	0385ba83          	ld	s5,56(a1)
    80002800:	0405bb03          	ld	s6,64(a1)
    80002804:	0485bb83          	ld	s7,72(a1)
    80002808:	0505bc03          	ld	s8,80(a1)
    8000280c:	0585bc83          	ld	s9,88(a1)
    80002810:	0605bd03          	ld	s10,96(a1)
    80002814:	0685bd83          	ld	s11,104(a1)
    80002818:	8082                	ret

000000008000281a <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    8000281a:	1141                	addi	sp,sp,-16
    8000281c:	e406                	sd	ra,8(sp)
    8000281e:	e022                	sd	s0,0(sp)
    80002820:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002822:	00006597          	auipc	a1,0x6
    80002826:	ad658593          	addi	a1,a1,-1322 # 800082f8 <states.0+0x30>
    8000282a:	00015517          	auipc	a0,0x15
    8000282e:	f8650513          	addi	a0,a0,-122 # 800177b0 <tickslock>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	314080e7          	jalr	788(ra) # 80000b46 <initlock>
}
    8000283a:	60a2                	ld	ra,8(sp)
    8000283c:	6402                	ld	s0,0(sp)
    8000283e:	0141                	addi	sp,sp,16
    80002840:	8082                	ret

0000000080002842 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002842:	1141                	addi	sp,sp,-16
    80002844:	e422                	sd	s0,8(sp)
    80002846:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002848:	00003797          	auipc	a5,0x3
    8000284c:	68878793          	addi	a5,a5,1672 # 80005ed0 <kernelvec>
    80002850:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002854:	6422                	ld	s0,8(sp)
    80002856:	0141                	addi	sp,sp,16
    80002858:	8082                	ret

000000008000285a <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000285a:	1141                	addi	sp,sp,-16
    8000285c:	e406                	sd	ra,8(sp)
    8000285e:	e022                	sd	s0,0(sp)
    80002860:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	14a080e7          	jalr	330(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000286a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000286e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002870:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002874:	00004697          	auipc	a3,0x4
    80002878:	78c68693          	addi	a3,a3,1932 # 80007000 <_trampoline>
    8000287c:	00004717          	auipc	a4,0x4
    80002880:	78470713          	addi	a4,a4,1924 # 80007000 <_trampoline>
    80002884:	8f15                	sub	a4,a4,a3
    80002886:	040007b7          	lui	a5,0x4000
    8000288a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000288c:	07b2                	slli	a5,a5,0xc
    8000288e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002890:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002894:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002896:	18002673          	csrr	a2,satp
    8000289a:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000289c:	6d30                	ld	a2,88(a0)
    8000289e:	6138                	ld	a4,64(a0)
    800028a0:	6585                	lui	a1,0x1
    800028a2:	972e                	add	a4,a4,a1
    800028a4:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028a6:	6d38                	ld	a4,88(a0)
    800028a8:	00000617          	auipc	a2,0x0
    800028ac:	13e60613          	addi	a2,a2,318 # 800029e6 <usertrap>
    800028b0:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    800028b2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028b4:	8612                	mv	a2,tp
    800028b6:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b8:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028bc:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028c0:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c4:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028c8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ca:	6f18                	ld	a4,24(a4)
    800028cc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028d0:	6928                	ld	a0,80(a0)
    800028d2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028d4:	00004717          	auipc	a4,0x4
    800028d8:	7c870713          	addi	a4,a4,1992 # 8000709c <userret>
    800028dc:	8f15                	sub	a4,a4,a3
    800028de:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028e0:	577d                	li	a4,-1
    800028e2:	177e                	slli	a4,a4,0x3f
    800028e4:	8d59                	or	a0,a0,a4
    800028e6:	9782                	jalr	a5
}
    800028e8:	60a2                	ld	ra,8(sp)
    800028ea:	6402                	ld	s0,0(sp)
    800028ec:	0141                	addi	sp,sp,16
    800028ee:	8082                	ret

00000000800028f0 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028f0:	1101                	addi	sp,sp,-32
    800028f2:	ec06                	sd	ra,24(sp)
    800028f4:	e822                	sd	s0,16(sp)
    800028f6:	e426                	sd	s1,8(sp)
    800028f8:	e04a                	sd	s2,0(sp)
    800028fa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028fc:	00015917          	auipc	s2,0x15
    80002900:	eb490913          	addi	s2,s2,-332 # 800177b0 <tickslock>
    80002904:	854a                	mv	a0,s2
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	2d0080e7          	jalr	720(ra) # 80000bd6 <acquire>
  ticks++;
    8000290e:	00006497          	auipc	s1,0x6
    80002912:	00248493          	addi	s1,s1,2 # 80008910 <ticks>
    80002916:	409c                	lw	a5,0(s1)
    80002918:	2785                	addiw	a5,a5,1
    8000291a:	c09c                	sw	a5,0(s1)
  update_time();
    8000291c:	00000097          	auipc	ra,0x0
    80002920:	e18080e7          	jalr	-488(ra) # 80002734 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002924:	8526                	mv	a0,s1
    80002926:	fffff097          	auipc	ra,0xfffff
    8000292a:	7b6080e7          	jalr	1974(ra) # 800020dc <wakeup>
  release(&tickslock);
    8000292e:	854a                	mv	a0,s2
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	35a080e7          	jalr	858(ra) # 80000c8a <release>
}
    80002938:	60e2                	ld	ra,24(sp)
    8000293a:	6442                	ld	s0,16(sp)
    8000293c:	64a2                	ld	s1,8(sp)
    8000293e:	6902                	ld	s2,0(sp)
    80002940:	6105                	addi	sp,sp,32
    80002942:	8082                	ret

0000000080002944 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002944:	1101                	addi	sp,sp,-32
    80002946:	ec06                	sd	ra,24(sp)
    80002948:	e822                	sd	s0,16(sp)
    8000294a:	e426                	sd	s1,8(sp)
    8000294c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002952:	00074d63          	bltz	a4,8000296c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002956:	57fd                	li	a5,-1
    80002958:	17fe                	slli	a5,a5,0x3f
    8000295a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    8000295c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    8000295e:	06f70363          	beq	a4,a5,800029c4 <devintr+0x80>
  }
}
    80002962:	60e2                	ld	ra,24(sp)
    80002964:	6442                	ld	s0,16(sp)
    80002966:	64a2                	ld	s1,8(sp)
    80002968:	6105                	addi	sp,sp,32
    8000296a:	8082                	ret
      (scause & 0xff) == 9)
    8000296c:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002970:	46a5                	li	a3,9
    80002972:	fed792e3          	bne	a5,a3,80002956 <devintr+0x12>
    int irq = plic_claim();
    80002976:	00003097          	auipc	ra,0x3
    8000297a:	662080e7          	jalr	1634(ra) # 80005fd8 <plic_claim>
    8000297e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002980:	47a9                	li	a5,10
    80002982:	02f50763          	beq	a0,a5,800029b0 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002986:	4785                	li	a5,1
    80002988:	02f50963          	beq	a0,a5,800029ba <devintr+0x76>
    return 1;
    8000298c:	4505                	li	a0,1
    else if (irq)
    8000298e:	d8f1                	beqz	s1,80002962 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002990:	85a6                	mv	a1,s1
    80002992:	00006517          	auipc	a0,0x6
    80002996:	96e50513          	addi	a0,a0,-1682 # 80008300 <states.0+0x38>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	bf0080e7          	jalr	-1040(ra) # 8000058a <printf>
      plic_complete(irq);
    800029a2:	8526                	mv	a0,s1
    800029a4:	00003097          	auipc	ra,0x3
    800029a8:	658080e7          	jalr	1624(ra) # 80005ffc <plic_complete>
    return 1;
    800029ac:	4505                	li	a0,1
    800029ae:	bf55                	j	80002962 <devintr+0x1e>
      uartintr();
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	fe8080e7          	jalr	-24(ra) # 80000998 <uartintr>
    800029b8:	b7ed                	j	800029a2 <devintr+0x5e>
      virtio_disk_intr();
    800029ba:	00004097          	auipc	ra,0x4
    800029be:	b0a080e7          	jalr	-1270(ra) # 800064c4 <virtio_disk_intr>
    800029c2:	b7c5                	j	800029a2 <devintr+0x5e>
    if (cpuid() == 0)
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	fbc080e7          	jalr	-68(ra) # 80001980 <cpuid>
    800029cc:	c901                	beqz	a0,800029dc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029ce:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029d2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029d4:	14479073          	csrw	sip,a5
    return 2;
    800029d8:	4509                	li	a0,2
    800029da:	b761                	j	80002962 <devintr+0x1e>
      clockintr();
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	f14080e7          	jalr	-236(ra) # 800028f0 <clockintr>
    800029e4:	b7ed                	j	800029ce <devintr+0x8a>

00000000800029e6 <usertrap>:
{
    800029e6:	1101                	addi	sp,sp,-32
    800029e8:	ec06                	sd	ra,24(sp)
    800029ea:	e822                	sd	s0,16(sp)
    800029ec:	e426                	sd	s1,8(sp)
    800029ee:	e04a                	sd	s2,0(sp)
    800029f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029f6:	1007f793          	andi	a5,a5,256
    800029fa:	e7a5                	bnez	a5,80002a62 <usertrap+0x7c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fc:	00003797          	auipc	a5,0x3
    80002a00:	4d478793          	addi	a5,a5,1236 # 80005ed0 <kernelvec>
    80002a04:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	fa4080e7          	jalr	-92(ra) # 800019ac <myproc>
    80002a10:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a12:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a14:	14102773          	csrr	a4,sepc
    80002a18:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1a:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a1e:	47a1                	li	a5,8
    80002a20:	04f70963          	beq	a4,a5,80002a72 <usertrap+0x8c>
  else if ((which_dev = devintr()) != 0)
    80002a24:	00000097          	auipc	ra,0x0
    80002a28:	f20080e7          	jalr	-224(ra) # 80002944 <devintr>
    80002a2c:	892a                	mv	s2,a0
    80002a2e:	c561                	beqz	a0,80002af6 <usertrap+0x110>
    if (which_dev == 2)
    80002a30:	4789                	li	a5,2
    80002a32:	06f51463          	bne	a0,a5,80002a9a <usertrap+0xb4>
      p->cur_ticks++;
    80002a36:	1844a783          	lw	a5,388(s1)
    80002a3a:	2785                	addiw	a5,a5,1
    80002a3c:	0007871b          	sext.w	a4,a5
    80002a40:	18f4a223          	sw	a5,388(s1)
      if (p->cur_ticks == p->ticks && p->alarm_on == 0)
    80002a44:	1804a783          	lw	a5,384(s1)
    80002a48:	06e78f63          	beq	a5,a4,80002ac6 <usertrap+0xe0>
  if (killed(p))
    80002a4c:	8526                	mv	a0,s1
    80002a4e:	00000097          	auipc	ra,0x0
    80002a52:	8de080e7          	jalr	-1826(ra) # 8000232c <killed>
    80002a56:	e575                	bnez	a0,80002b42 <usertrap+0x15c>
    yield();
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	5e4080e7          	jalr	1508(ra) # 8000203c <yield>
    80002a60:	a099                	j	80002aa6 <usertrap+0xc0>
    panic("usertrap: not from user mode");
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	8be50513          	addi	a0,a0,-1858 # 80008320 <states.0+0x58>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	ad6080e7          	jalr	-1322(ra) # 80000540 <panic>
    if (killed(p))
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	8ba080e7          	jalr	-1862(ra) # 8000232c <killed>
    80002a7a:	e121                	bnez	a0,80002aba <usertrap+0xd4>
    p->trapframe->epc += 4;
    80002a7c:	6cb8                	ld	a4,88(s1)
    80002a7e:	6f1c                	ld	a5,24(a4)
    80002a80:	0791                	addi	a5,a5,4
    80002a82:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a88:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a8c:	10079073          	csrw	sstatus,a5
    syscall();
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	308080e7          	jalr	776(ra) # 80002d98 <syscall>
  int which_dev = 0;
    80002a98:	4901                	li	s2,0
  if (killed(p))
    80002a9a:	8526                	mv	a0,s1
    80002a9c:	00000097          	auipc	ra,0x0
    80002aa0:	890080e7          	jalr	-1904(ra) # 8000232c <killed>
    80002aa4:	e551                	bnez	a0,80002b30 <usertrap+0x14a>
  usertrapret();
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	db4080e7          	jalr	-588(ra) # 8000285a <usertrapret>
}
    80002aae:	60e2                	ld	ra,24(sp)
    80002ab0:	6442                	ld	s0,16(sp)
    80002ab2:	64a2                	ld	s1,8(sp)
    80002ab4:	6902                	ld	s2,0(sp)
    80002ab6:	6105                	addi	sp,sp,32
    80002ab8:	8082                	ret
      exit(-1);
    80002aba:	557d                	li	a0,-1
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	6f0080e7          	jalr	1776(ra) # 800021ac <exit>
    80002ac4:	bf65                	j	80002a7c <usertrap+0x96>
      if (p->cur_ticks == p->ticks && p->alarm_on == 0)
    80002ac6:	1904a783          	lw	a5,400(s1)
    80002aca:	f3c9                	bnez	a5,80002a4c <usertrap+0x66>
        struct trapframe *tf = kalloc();
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	01a080e7          	jalr	26(ra) # 80000ae6 <kalloc>
    80002ad4:	892a                	mv	s2,a0
        memmove(tf, p->trapframe, PGSIZE);
    80002ad6:	6605                	lui	a2,0x1
    80002ad8:	6cac                	ld	a1,88(s1)
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	254080e7          	jalr	596(ra) # 80000d2e <memmove>
        p->alarm_tf = tf;
    80002ae2:	1924b423          	sd	s2,392(s1)
        p->alarm_on = 1;
    80002ae6:	4785                	li	a5,1
    80002ae8:	18f4a823          	sw	a5,400(s1)
        p->trapframe->epc = p->handler;
    80002aec:	6cbc                	ld	a5,88(s1)
    80002aee:	1784b703          	ld	a4,376(s1)
    80002af2:	ef98                	sd	a4,24(a5)
    80002af4:	bfa1                	j	80002a4c <usertrap+0x66>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002af6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002afa:	5890                	lw	a2,48(s1)
    80002afc:	00006517          	auipc	a0,0x6
    80002b00:	84450513          	addi	a0,a0,-1980 # 80008340 <states.0+0x78>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	a86080e7          	jalr	-1402(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b10:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	85c50513          	addi	a0,a0,-1956 # 80008370 <states.0+0xa8>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a6e080e7          	jalr	-1426(ra) # 8000058a <printf>
    setkilled(p);
    80002b24:	8526                	mv	a0,s1
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	7da080e7          	jalr	2010(ra) # 80002300 <setkilled>
    80002b2e:	b7b5                	j	80002a9a <usertrap+0xb4>
    exit(-1);
    80002b30:	557d                	li	a0,-1
    80002b32:	fffff097          	auipc	ra,0xfffff
    80002b36:	67a080e7          	jalr	1658(ra) # 800021ac <exit>
  if (which_dev == 2)
    80002b3a:	4789                	li	a5,2
    80002b3c:	f6f915e3          	bne	s2,a5,80002aa6 <usertrap+0xc0>
    80002b40:	bf21                	j	80002a58 <usertrap+0x72>
    exit(-1);
    80002b42:	557d                	li	a0,-1
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	668080e7          	jalr	1640(ra) # 800021ac <exit>
  if (which_dev == 2)
    80002b4c:	b731                	j	80002a58 <usertrap+0x72>

0000000080002b4e <kerneltrap>:
{
    80002b4e:	7179                	addi	sp,sp,-48
    80002b50:	f406                	sd	ra,40(sp)
    80002b52:	f022                	sd	s0,32(sp)
    80002b54:	ec26                	sd	s1,24(sp)
    80002b56:	e84a                	sd	s2,16(sp)
    80002b58:	e44e                	sd	s3,8(sp)
    80002b5a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b5c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b60:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b64:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b68:	1004f793          	andi	a5,s1,256
    80002b6c:	cb85                	beqz	a5,80002b9c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b72:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b74:	ef85                	bnez	a5,80002bac <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b76:	00000097          	auipc	ra,0x0
    80002b7a:	dce080e7          	jalr	-562(ra) # 80002944 <devintr>
    80002b7e:	cd1d                	beqz	a0,80002bbc <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b80:	4789                	li	a5,2
    80002b82:	06f50a63          	beq	a0,a5,80002bf6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b86:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b8a:	10049073          	csrw	sstatus,s1
}
    80002b8e:	70a2                	ld	ra,40(sp)
    80002b90:	7402                	ld	s0,32(sp)
    80002b92:	64e2                	ld	s1,24(sp)
    80002b94:	6942                	ld	s2,16(sp)
    80002b96:	69a2                	ld	s3,8(sp)
    80002b98:	6145                	addi	sp,sp,48
    80002b9a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b9c:	00005517          	auipc	a0,0x5
    80002ba0:	7f450513          	addi	a0,a0,2036 # 80008390 <states.0+0xc8>
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	99c080e7          	jalr	-1636(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002bac:	00006517          	auipc	a0,0x6
    80002bb0:	80c50513          	addi	a0,a0,-2036 # 800083b8 <states.0+0xf0>
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	98c080e7          	jalr	-1652(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002bbc:	85ce                	mv	a1,s3
    80002bbe:	00006517          	auipc	a0,0x6
    80002bc2:	81a50513          	addi	a0,a0,-2022 # 800083d8 <states.0+0x110>
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	9c4080e7          	jalr	-1596(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bd6:	00006517          	auipc	a0,0x6
    80002bda:	81250513          	addi	a0,a0,-2030 # 800083e8 <states.0+0x120>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	9ac080e7          	jalr	-1620(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002be6:	00006517          	auipc	a0,0x6
    80002bea:	81a50513          	addi	a0,a0,-2022 # 80008400 <states.0+0x138>
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	952080e7          	jalr	-1710(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	db6080e7          	jalr	-586(ra) # 800019ac <myproc>
    80002bfe:	d541                	beqz	a0,80002b86 <kerneltrap+0x38>
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	dac080e7          	jalr	-596(ra) # 800019ac <myproc>
    80002c08:	4d18                	lw	a4,24(a0)
    80002c0a:	4791                	li	a5,4
    80002c0c:	f6f71de3          	bne	a4,a5,80002b86 <kerneltrap+0x38>
    yield();
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	42c080e7          	jalr	1068(ra) # 8000203c <yield>
    80002c18:	b7bd                	j	80002b86 <kerneltrap+0x38>

0000000080002c1a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c1a:	1101                	addi	sp,sp,-32
    80002c1c:	ec06                	sd	ra,24(sp)
    80002c1e:	e822                	sd	s0,16(sp)
    80002c20:	e426                	sd	s1,8(sp)
    80002c22:	1000                	addi	s0,sp,32
    80002c24:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	d86080e7          	jalr	-634(ra) # 800019ac <myproc>
  switch (n) {
    80002c2e:	4795                	li	a5,5
    80002c30:	0497e163          	bltu	a5,s1,80002c72 <argraw+0x58>
    80002c34:	048a                	slli	s1,s1,0x2
    80002c36:	00006717          	auipc	a4,0x6
    80002c3a:	80270713          	addi	a4,a4,-2046 # 80008438 <states.0+0x170>
    80002c3e:	94ba                	add	s1,s1,a4
    80002c40:	409c                	lw	a5,0(s1)
    80002c42:	97ba                	add	a5,a5,a4
    80002c44:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c46:	6d3c                	ld	a5,88(a0)
    80002c48:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c4a:	60e2                	ld	ra,24(sp)
    80002c4c:	6442                	ld	s0,16(sp)
    80002c4e:	64a2                	ld	s1,8(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret
    return p->trapframe->a1;
    80002c54:	6d3c                	ld	a5,88(a0)
    80002c56:	7fa8                	ld	a0,120(a5)
    80002c58:	bfcd                	j	80002c4a <argraw+0x30>
    return p->trapframe->a2;
    80002c5a:	6d3c                	ld	a5,88(a0)
    80002c5c:	63c8                	ld	a0,128(a5)
    80002c5e:	b7f5                	j	80002c4a <argraw+0x30>
    return p->trapframe->a3;
    80002c60:	6d3c                	ld	a5,88(a0)
    80002c62:	67c8                	ld	a0,136(a5)
    80002c64:	b7dd                	j	80002c4a <argraw+0x30>
    return p->trapframe->a4;
    80002c66:	6d3c                	ld	a5,88(a0)
    80002c68:	6bc8                	ld	a0,144(a5)
    80002c6a:	b7c5                	j	80002c4a <argraw+0x30>
    return p->trapframe->a5;
    80002c6c:	6d3c                	ld	a5,88(a0)
    80002c6e:	6fc8                	ld	a0,152(a5)
    80002c70:	bfe9                	j	80002c4a <argraw+0x30>
  panic("argraw");
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	79e50513          	addi	a0,a0,1950 # 80008410 <states.0+0x148>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	8c6080e7          	jalr	-1850(ra) # 80000540 <panic>

0000000080002c82 <fetchaddr>:
{
    80002c82:	1101                	addi	sp,sp,-32
    80002c84:	ec06                	sd	ra,24(sp)
    80002c86:	e822                	sd	s0,16(sp)
    80002c88:	e426                	sd	s1,8(sp)
    80002c8a:	e04a                	sd	s2,0(sp)
    80002c8c:	1000                	addi	s0,sp,32
    80002c8e:	84aa                	mv	s1,a0
    80002c90:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	d1a080e7          	jalr	-742(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c9a:	653c                	ld	a5,72(a0)
    80002c9c:	02f4f863          	bgeu	s1,a5,80002ccc <fetchaddr+0x4a>
    80002ca0:	00848713          	addi	a4,s1,8
    80002ca4:	02e7e663          	bltu	a5,a4,80002cd0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ca8:	46a1                	li	a3,8
    80002caa:	8626                	mv	a2,s1
    80002cac:	85ca                	mv	a1,s2
    80002cae:	6928                	ld	a0,80(a0)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	a48080e7          	jalr	-1464(ra) # 800016f8 <copyin>
    80002cb8:	00a03533          	snez	a0,a0
    80002cbc:	40a00533          	neg	a0,a0
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6902                	ld	s2,0(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret
    return -1;
    80002ccc:	557d                	li	a0,-1
    80002cce:	bfcd                	j	80002cc0 <fetchaddr+0x3e>
    80002cd0:	557d                	li	a0,-1
    80002cd2:	b7fd                	j	80002cc0 <fetchaddr+0x3e>

0000000080002cd4 <fetchstr>:
{
    80002cd4:	7179                	addi	sp,sp,-48
    80002cd6:	f406                	sd	ra,40(sp)
    80002cd8:	f022                	sd	s0,32(sp)
    80002cda:	ec26                	sd	s1,24(sp)
    80002cdc:	e84a                	sd	s2,16(sp)
    80002cde:	e44e                	sd	s3,8(sp)
    80002ce0:	1800                	addi	s0,sp,48
    80002ce2:	892a                	mv	s2,a0
    80002ce4:	84ae                	mv	s1,a1
    80002ce6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	cc4080e7          	jalr	-828(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cf0:	86ce                	mv	a3,s3
    80002cf2:	864a                	mv	a2,s2
    80002cf4:	85a6                	mv	a1,s1
    80002cf6:	6928                	ld	a0,80(a0)
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	a8e080e7          	jalr	-1394(ra) # 80001786 <copyinstr>
    80002d00:	00054e63          	bltz	a0,80002d1c <fetchstr+0x48>
  return strlen(buf);
    80002d04:	8526                	mv	a0,s1
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	148080e7          	jalr	328(ra) # 80000e4e <strlen>
}
    80002d0e:	70a2                	ld	ra,40(sp)
    80002d10:	7402                	ld	s0,32(sp)
    80002d12:	64e2                	ld	s1,24(sp)
    80002d14:	6942                	ld	s2,16(sp)
    80002d16:	69a2                	ld	s3,8(sp)
    80002d18:	6145                	addi	sp,sp,48
    80002d1a:	8082                	ret
    return -1;
    80002d1c:	557d                	li	a0,-1
    80002d1e:	bfc5                	j	80002d0e <fetchstr+0x3a>

0000000080002d20 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d20:	1101                	addi	sp,sp,-32
    80002d22:	ec06                	sd	ra,24(sp)
    80002d24:	e822                	sd	s0,16(sp)
    80002d26:	e426                	sd	s1,8(sp)
    80002d28:	1000                	addi	s0,sp,32
    80002d2a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	eee080e7          	jalr	-274(ra) # 80002c1a <argraw>
    80002d34:	c088                	sw	a0,0(s1)
}
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	64a2                	ld	s1,8(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret

0000000080002d40 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d40:	1101                	addi	sp,sp,-32
    80002d42:	ec06                	sd	ra,24(sp)
    80002d44:	e822                	sd	s0,16(sp)
    80002d46:	e426                	sd	s1,8(sp)
    80002d48:	1000                	addi	s0,sp,32
    80002d4a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	ece080e7          	jalr	-306(ra) # 80002c1a <argraw>
    80002d54:	e088                	sd	a0,0(s1)
}
    80002d56:	60e2                	ld	ra,24(sp)
    80002d58:	6442                	ld	s0,16(sp)
    80002d5a:	64a2                	ld	s1,8(sp)
    80002d5c:	6105                	addi	sp,sp,32
    80002d5e:	8082                	ret

0000000080002d60 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d60:	7179                	addi	sp,sp,-48
    80002d62:	f406                	sd	ra,40(sp)
    80002d64:	f022                	sd	s0,32(sp)
    80002d66:	ec26                	sd	s1,24(sp)
    80002d68:	e84a                	sd	s2,16(sp)
    80002d6a:	1800                	addi	s0,sp,48
    80002d6c:	84ae                	mv	s1,a1
    80002d6e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d70:	fd840593          	addi	a1,s0,-40
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	fcc080e7          	jalr	-52(ra) # 80002d40 <argaddr>
  return fetchstr(addr, buf, max);
    80002d7c:	864a                	mv	a2,s2
    80002d7e:	85a6                	mv	a1,s1
    80002d80:	fd843503          	ld	a0,-40(s0)
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	f50080e7          	jalr	-176(ra) # 80002cd4 <fetchstr>
}
    80002d8c:	70a2                	ld	ra,40(sp)
    80002d8e:	7402                	ld	s0,32(sp)
    80002d90:	64e2                	ld	s1,24(sp)
    80002d92:	6942                	ld	s2,16(sp)
    80002d94:	6145                	addi	sp,sp,48
    80002d96:	8082                	ret

0000000080002d98 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002d98:	1101                	addi	sp,sp,-32
    80002d9a:	ec06                	sd	ra,24(sp)
    80002d9c:	e822                	sd	s0,16(sp)
    80002d9e:	e426                	sd	s1,8(sp)
    80002da0:	e04a                	sd	s2,0(sp)
    80002da2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	c08080e7          	jalr	-1016(ra) # 800019ac <myproc>
    80002dac:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dae:	05853903          	ld	s2,88(a0)
    80002db2:	0a893783          	ld	a5,168(s2)
    80002db6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002dba:	37fd                	addiw	a5,a5,-1
    80002dbc:	4761                	li	a4,24
    80002dbe:	00f76f63          	bltu	a4,a5,80002ddc <syscall+0x44>
    80002dc2:	00369713          	slli	a4,a3,0x3
    80002dc6:	00005797          	auipc	a5,0x5
    80002dca:	68a78793          	addi	a5,a5,1674 # 80008450 <syscalls>
    80002dce:	97ba                	add	a5,a5,a4
    80002dd0:	639c                	ld	a5,0(a5)
    80002dd2:	c789                	beqz	a5,80002ddc <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002dd4:	9782                	jalr	a5
    80002dd6:	06a93823          	sd	a0,112(s2)
    80002dda:	a839                	j	80002df8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ddc:	15848613          	addi	a2,s1,344
    80002de0:	588c                	lw	a1,48(s1)
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	63650513          	addi	a0,a0,1590 # 80008418 <states.0+0x150>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	7a0080e7          	jalr	1952(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002df2:	6cbc                	ld	a5,88(s1)
    80002df4:	577d                	li	a4,-1
    80002df6:	fbb8                	sd	a4,112(a5)
  }
}
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	64a2                	ld	s1,8(sp)
    80002dfe:	6902                	ld	s2,0(sp)
    80002e00:	6105                	addi	sp,sp,32
    80002e02:	8082                	ret

0000000080002e04 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e0c:	fec40593          	addi	a1,s0,-20
    80002e10:	4501                	li	a0,0
    80002e12:	00000097          	auipc	ra,0x0
    80002e16:	f0e080e7          	jalr	-242(ra) # 80002d20 <argint>
  exit(n);
    80002e1a:	fec42503          	lw	a0,-20(s0)
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	38e080e7          	jalr	910(ra) # 800021ac <exit>
  return 0; // not reached
}
    80002e26:	4501                	li	a0,0
    80002e28:	60e2                	ld	ra,24(sp)
    80002e2a:	6442                	ld	s0,16(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret

0000000080002e30 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e30:	1141                	addi	sp,sp,-16
    80002e32:	e406                	sd	ra,8(sp)
    80002e34:	e022                	sd	s0,0(sp)
    80002e36:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	b74080e7          	jalr	-1164(ra) # 800019ac <myproc>
}
    80002e40:	5908                	lw	a0,48(a0)
    80002e42:	60a2                	ld	ra,8(sp)
    80002e44:	6402                	ld	s0,0(sp)
    80002e46:	0141                	addi	sp,sp,16
    80002e48:	8082                	ret

0000000080002e4a <sys_fork>:

uint64
sys_fork(void)
{
    80002e4a:	1141                	addi	sp,sp,-16
    80002e4c:	e406                	sd	ra,8(sp)
    80002e4e:	e022                	sd	s0,0(sp)
    80002e50:	0800                	addi	s0,sp,16
  return fork();
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	f34080e7          	jalr	-204(ra) # 80001d86 <fork>
}
    80002e5a:	60a2                	ld	ra,8(sp)
    80002e5c:	6402                	ld	s0,0(sp)
    80002e5e:	0141                	addi	sp,sp,16
    80002e60:	8082                	ret

0000000080002e62 <sys_wait>:

uint64
sys_wait(void)
{
    80002e62:	1101                	addi	sp,sp,-32
    80002e64:	ec06                	sd	ra,24(sp)
    80002e66:	e822                	sd	s0,16(sp)
    80002e68:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e6a:	fe840593          	addi	a1,s0,-24
    80002e6e:	4501                	li	a0,0
    80002e70:	00000097          	auipc	ra,0x0
    80002e74:	ed0080e7          	jalr	-304(ra) # 80002d40 <argaddr>
  return wait(p);
    80002e78:	fe843503          	ld	a0,-24(s0)
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	4e2080e7          	jalr	1250(ra) # 8000235e <wait>
}
    80002e84:	60e2                	ld	ra,24(sp)
    80002e86:	6442                	ld	s0,16(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret

0000000080002e8c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e8c:	7179                	addi	sp,sp,-48
    80002e8e:	f406                	sd	ra,40(sp)
    80002e90:	f022                	sd	s0,32(sp)
    80002e92:	ec26                	sd	s1,24(sp)
    80002e94:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e96:	fdc40593          	addi	a1,s0,-36
    80002e9a:	4501                	li	a0,0
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	e84080e7          	jalr	-380(ra) # 80002d20 <argint>
  addr = myproc()->sz;
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	b08080e7          	jalr	-1272(ra) # 800019ac <myproc>
    80002eac:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002eae:	fdc42503          	lw	a0,-36(s0)
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	e78080e7          	jalr	-392(ra) # 80001d2a <growproc>
    80002eba:	00054863          	bltz	a0,80002eca <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ebe:	8526                	mv	a0,s1
    80002ec0:	70a2                	ld	ra,40(sp)
    80002ec2:	7402                	ld	s0,32(sp)
    80002ec4:	64e2                	ld	s1,24(sp)
    80002ec6:	6145                	addi	sp,sp,48
    80002ec8:	8082                	ret
    return -1;
    80002eca:	54fd                	li	s1,-1
    80002ecc:	bfcd                	j	80002ebe <sys_sbrk+0x32>

0000000080002ece <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ece:	7139                	addi	sp,sp,-64
    80002ed0:	fc06                	sd	ra,56(sp)
    80002ed2:	f822                	sd	s0,48(sp)
    80002ed4:	f426                	sd	s1,40(sp)
    80002ed6:	f04a                	sd	s2,32(sp)
    80002ed8:	ec4e                	sd	s3,24(sp)
    80002eda:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002edc:	fcc40593          	addi	a1,s0,-52
    80002ee0:	4501                	li	a0,0
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	e3e080e7          	jalr	-450(ra) # 80002d20 <argint>
  acquire(&tickslock);
    80002eea:	00015517          	auipc	a0,0x15
    80002eee:	8c650513          	addi	a0,a0,-1850 # 800177b0 <tickslock>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	ce4080e7          	jalr	-796(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002efa:	00006917          	auipc	s2,0x6
    80002efe:	a1692903          	lw	s2,-1514(s2) # 80008910 <ticks>
  while (ticks - ticks0 < n)
    80002f02:	fcc42783          	lw	a5,-52(s0)
    80002f06:	cf9d                	beqz	a5,80002f44 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f08:	00015997          	auipc	s3,0x15
    80002f0c:	8a898993          	addi	s3,s3,-1880 # 800177b0 <tickslock>
    80002f10:	00006497          	auipc	s1,0x6
    80002f14:	a0048493          	addi	s1,s1,-1536 # 80008910 <ticks>
    if (killed(myproc()))
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	a94080e7          	jalr	-1388(ra) # 800019ac <myproc>
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	40c080e7          	jalr	1036(ra) # 8000232c <killed>
    80002f28:	ed15                	bnez	a0,80002f64 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f2a:	85ce                	mv	a1,s3
    80002f2c:	8526                	mv	a0,s1
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	14a080e7          	jalr	330(ra) # 80002078 <sleep>
  while (ticks - ticks0 < n)
    80002f36:	409c                	lw	a5,0(s1)
    80002f38:	412787bb          	subw	a5,a5,s2
    80002f3c:	fcc42703          	lw	a4,-52(s0)
    80002f40:	fce7ece3          	bltu	a5,a4,80002f18 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f44:	00015517          	auipc	a0,0x15
    80002f48:	86c50513          	addi	a0,a0,-1940 # 800177b0 <tickslock>
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	d3e080e7          	jalr	-706(ra) # 80000c8a <release>
  return 0;
    80002f54:	4501                	li	a0,0
}
    80002f56:	70e2                	ld	ra,56(sp)
    80002f58:	7442                	ld	s0,48(sp)
    80002f5a:	74a2                	ld	s1,40(sp)
    80002f5c:	7902                	ld	s2,32(sp)
    80002f5e:	69e2                	ld	s3,24(sp)
    80002f60:	6121                	addi	sp,sp,64
    80002f62:	8082                	ret
      release(&tickslock);
    80002f64:	00015517          	auipc	a0,0x15
    80002f68:	84c50513          	addi	a0,a0,-1972 # 800177b0 <tickslock>
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	d1e080e7          	jalr	-738(ra) # 80000c8a <release>
      return -1;
    80002f74:	557d                	li	a0,-1
    80002f76:	b7c5                	j	80002f56 <sys_sleep+0x88>

0000000080002f78 <sys_kill>:

uint64
sys_kill(void)
{
    80002f78:	1101                	addi	sp,sp,-32
    80002f7a:	ec06                	sd	ra,24(sp)
    80002f7c:	e822                	sd	s0,16(sp)
    80002f7e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f80:	fec40593          	addi	a1,s0,-20
    80002f84:	4501                	li	a0,0
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	d9a080e7          	jalr	-614(ra) # 80002d20 <argint>
  return kill(pid);
    80002f8e:	fec42503          	lw	a0,-20(s0)
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	2fc080e7          	jalr	764(ra) # 8000228e <kill>
}
    80002f9a:	60e2                	ld	ra,24(sp)
    80002f9c:	6442                	ld	s0,16(sp)
    80002f9e:	6105                	addi	sp,sp,32
    80002fa0:	8082                	ret

0000000080002fa2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fa2:	1101                	addi	sp,sp,-32
    80002fa4:	ec06                	sd	ra,24(sp)
    80002fa6:	e822                	sd	s0,16(sp)
    80002fa8:	e426                	sd	s1,8(sp)
    80002faa:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fac:	00015517          	auipc	a0,0x15
    80002fb0:	80450513          	addi	a0,a0,-2044 # 800177b0 <tickslock>
    80002fb4:	ffffe097          	auipc	ra,0xffffe
    80002fb8:	c22080e7          	jalr	-990(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002fbc:	00006497          	auipc	s1,0x6
    80002fc0:	9544a483          	lw	s1,-1708(s1) # 80008910 <ticks>
  release(&tickslock);
    80002fc4:	00014517          	auipc	a0,0x14
    80002fc8:	7ec50513          	addi	a0,a0,2028 # 800177b0 <tickslock>
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	cbe080e7          	jalr	-834(ra) # 80000c8a <release>
  return xticks;
}
    80002fd4:	02049513          	slli	a0,s1,0x20
    80002fd8:	9101                	srli	a0,a0,0x20
    80002fda:	60e2                	ld	ra,24(sp)
    80002fdc:	6442                	ld	s0,16(sp)
    80002fde:	64a2                	ld	s1,8(sp)
    80002fe0:	6105                	addi	sp,sp,32
    80002fe2:	8082                	ret

0000000080002fe4 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002fe4:	7139                	addi	sp,sp,-64
    80002fe6:	fc06                	sd	ra,56(sp)
    80002fe8:	f822                	sd	s0,48(sp)
    80002fea:	f426                	sd	s1,40(sp)
    80002fec:	f04a                	sd	s2,32(sp)
    80002fee:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80002ff0:	fd840593          	addi	a1,s0,-40
    80002ff4:	4501                	li	a0,0
    80002ff6:	00000097          	auipc	ra,0x0
    80002ffa:	d4a080e7          	jalr	-694(ra) # 80002d40 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80002ffe:	fd040593          	addi	a1,s0,-48
    80003002:	4505                	li	a0,1
    80003004:	00000097          	auipc	ra,0x0
    80003008:	d3c080e7          	jalr	-708(ra) # 80002d40 <argaddr>
  argaddr(2, &addr2);
    8000300c:	fc840593          	addi	a1,s0,-56
    80003010:	4509                	li	a0,2
    80003012:	00000097          	auipc	ra,0x0
    80003016:	d2e080e7          	jalr	-722(ra) # 80002d40 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000301a:	fc040613          	addi	a2,s0,-64
    8000301e:	fc440593          	addi	a1,s0,-60
    80003022:	fd843503          	ld	a0,-40(s0)
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	5c2080e7          	jalr	1474(ra) # 800025e8 <waitx>
    8000302e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	97c080e7          	jalr	-1668(ra) # 800019ac <myproc>
    80003038:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000303a:	4691                	li	a3,4
    8000303c:	fc440613          	addi	a2,s0,-60
    80003040:	fd043583          	ld	a1,-48(s0)
    80003044:	6928                	ld	a0,80(a0)
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	626080e7          	jalr	1574(ra) # 8000166c <copyout>
    return -1;
    8000304e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003050:	00054f63          	bltz	a0,8000306e <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003054:	4691                	li	a3,4
    80003056:	fc040613          	addi	a2,s0,-64
    8000305a:	fc843583          	ld	a1,-56(s0)
    8000305e:	68a8                	ld	a0,80(s1)
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	60c080e7          	jalr	1548(ra) # 8000166c <copyout>
    80003068:	00054a63          	bltz	a0,8000307c <sys_waitx+0x98>
    return -1;
  return ret;
    8000306c:	87ca                	mv	a5,s2
}
    8000306e:	853e                	mv	a0,a5
    80003070:	70e2                	ld	ra,56(sp)
    80003072:	7442                	ld	s0,48(sp)
    80003074:	74a2                	ld	s1,40(sp)
    80003076:	7902                	ld	s2,32(sp)
    80003078:	6121                	addi	sp,sp,64
    8000307a:	8082                	ret
    return -1;
    8000307c:	57fd                	li	a5,-1
    8000307e:	bfc5                	j	8000306e <sys_waitx+0x8a>

0000000080003080 <sys_getreadcount>:

uint64
sys_getreadcount(void)
{
    80003080:	1141                	addi	sp,sp,-16
    80003082:	e422                	sd	s0,8(sp)
    80003084:	0800                	addi	s0,sp,16
  return readcount;
}
    80003086:	00006517          	auipc	a0,0x6
    8000308a:	88e52503          	lw	a0,-1906(a0) # 80008914 <readcount>
    8000308e:	6422                	ld	s0,8(sp)
    80003090:	0141                	addi	sp,sp,16
    80003092:	8082                	ret

0000000080003094 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	1000                	addi	s0,sp,32
  uint64 addr;
  int ticks;

  argint(0, &ticks);
    8000309c:	fe440593          	addi	a1,s0,-28
    800030a0:	4501                	li	a0,0
    800030a2:	00000097          	auipc	ra,0x0
    800030a6:	c7e080e7          	jalr	-898(ra) # 80002d20 <argint>
  argaddr(1, &addr);
    800030aa:	fe840593          	addi	a1,s0,-24
    800030ae:	4505                	li	a0,1
    800030b0:	00000097          	auipc	ra,0x0
    800030b4:	c90080e7          	jalr	-880(ra) # 80002d40 <argaddr>

  myproc()->ticks = ticks;
    800030b8:	fffff097          	auipc	ra,0xfffff
    800030bc:	8f4080e7          	jalr	-1804(ra) # 800019ac <myproc>
    800030c0:	fe442783          	lw	a5,-28(s0)
    800030c4:	18f52023          	sw	a5,384(a0)
  myproc()->handler = addr;
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	8e4080e7          	jalr	-1820(ra) # 800019ac <myproc>
    800030d0:	fe843783          	ld	a5,-24(s0)
    800030d4:	16f53c23          	sd	a5,376(a0)

  return 0;
}
    800030d8:	4501                	li	a0,0
    800030da:	60e2                	ld	ra,24(sp)
    800030dc:	6442                	ld	s0,16(sp)
    800030de:	6105                	addi	sp,sp,32
    800030e0:	8082                	ret

00000000800030e2 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	e426                	sd	s1,8(sp)
    800030ea:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	8c0080e7          	jalr	-1856(ra) # 800019ac <myproc>
    800030f4:	84aa                	mv	s1,a0
  if (p->alarm_on == 1)
    800030f6:	19052703          	lw	a4,400(a0)
    800030fa:	4785                	li	a5,1
    800030fc:	00f70963          	beq	a4,a5,8000310e <sys_sigreturn+0x2c>
    kfree(p->alarm_tf);
    p->alarm_tf = 0;
    p->alarm_on = 0;
    p->cur_ticks = 0;
  }
  return p->trapframe->a0;
    80003100:	6cbc                	ld	a5,88(s1)
    80003102:	7ba8                	ld	a0,112(a5)
    80003104:	60e2                	ld	ra,24(sp)
    80003106:	6442                	ld	s0,16(sp)
    80003108:	64a2                	ld	s1,8(sp)
    8000310a:	6105                	addi	sp,sp,32
    8000310c:	8082                	ret
    memmove(p->trapframe, p->alarm_tf, PGSIZE);
    8000310e:	6605                	lui	a2,0x1
    80003110:	18853583          	ld	a1,392(a0)
    80003114:	6d28                	ld	a0,88(a0)
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	c18080e7          	jalr	-1000(ra) # 80000d2e <memmove>
    kfree(p->alarm_tf);
    8000311e:	1884b503          	ld	a0,392(s1)
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	8c6080e7          	jalr	-1850(ra) # 800009e8 <kfree>
    p->alarm_tf = 0;
    8000312a:	1804b423          	sd	zero,392(s1)
    p->alarm_on = 0;
    8000312e:	1804a823          	sw	zero,400(s1)
    p->cur_ticks = 0;
    80003132:	1804a223          	sw	zero,388(s1)
    80003136:	b7e9                	j	80003100 <sys_sigreturn+0x1e>

0000000080003138 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003138:	7179                	addi	sp,sp,-48
    8000313a:	f406                	sd	ra,40(sp)
    8000313c:	f022                	sd	s0,32(sp)
    8000313e:	ec26                	sd	s1,24(sp)
    80003140:	e84a                	sd	s2,16(sp)
    80003142:	e44e                	sd	s3,8(sp)
    80003144:	e052                	sd	s4,0(sp)
    80003146:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003148:	00005597          	auipc	a1,0x5
    8000314c:	3d858593          	addi	a1,a1,984 # 80008520 <syscalls+0xd0>
    80003150:	00014517          	auipc	a0,0x14
    80003154:	67850513          	addi	a0,a0,1656 # 800177c8 <bcache>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	9ee080e7          	jalr	-1554(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003160:	0001c797          	auipc	a5,0x1c
    80003164:	66878793          	addi	a5,a5,1640 # 8001f7c8 <bcache+0x8000>
    80003168:	0001d717          	auipc	a4,0x1d
    8000316c:	8c870713          	addi	a4,a4,-1848 # 8001fa30 <bcache+0x8268>
    80003170:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003174:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003178:	00014497          	auipc	s1,0x14
    8000317c:	66848493          	addi	s1,s1,1640 # 800177e0 <bcache+0x18>
    b->next = bcache.head.next;
    80003180:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003182:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003184:	00005a17          	auipc	s4,0x5
    80003188:	3a4a0a13          	addi	s4,s4,932 # 80008528 <syscalls+0xd8>
    b->next = bcache.head.next;
    8000318c:	2b893783          	ld	a5,696(s2)
    80003190:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003192:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003196:	85d2                	mv	a1,s4
    80003198:	01048513          	addi	a0,s1,16
    8000319c:	00001097          	auipc	ra,0x1
    800031a0:	4c8080e7          	jalr	1224(ra) # 80004664 <initsleeplock>
    bcache.head.next->prev = b;
    800031a4:	2b893783          	ld	a5,696(s2)
    800031a8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031aa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ae:	45848493          	addi	s1,s1,1112
    800031b2:	fd349de3          	bne	s1,s3,8000318c <binit+0x54>
  }
}
    800031b6:	70a2                	ld	ra,40(sp)
    800031b8:	7402                	ld	s0,32(sp)
    800031ba:	64e2                	ld	s1,24(sp)
    800031bc:	6942                	ld	s2,16(sp)
    800031be:	69a2                	ld	s3,8(sp)
    800031c0:	6a02                	ld	s4,0(sp)
    800031c2:	6145                	addi	sp,sp,48
    800031c4:	8082                	ret

00000000800031c6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031c6:	7179                	addi	sp,sp,-48
    800031c8:	f406                	sd	ra,40(sp)
    800031ca:	f022                	sd	s0,32(sp)
    800031cc:	ec26                	sd	s1,24(sp)
    800031ce:	e84a                	sd	s2,16(sp)
    800031d0:	e44e                	sd	s3,8(sp)
    800031d2:	1800                	addi	s0,sp,48
    800031d4:	892a                	mv	s2,a0
    800031d6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031d8:	00014517          	auipc	a0,0x14
    800031dc:	5f050513          	addi	a0,a0,1520 # 800177c8 <bcache>
    800031e0:	ffffe097          	auipc	ra,0xffffe
    800031e4:	9f6080e7          	jalr	-1546(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031e8:	0001d497          	auipc	s1,0x1d
    800031ec:	8984b483          	ld	s1,-1896(s1) # 8001fa80 <bcache+0x82b8>
    800031f0:	0001d797          	auipc	a5,0x1d
    800031f4:	84078793          	addi	a5,a5,-1984 # 8001fa30 <bcache+0x8268>
    800031f8:	02f48f63          	beq	s1,a5,80003236 <bread+0x70>
    800031fc:	873e                	mv	a4,a5
    800031fe:	a021                	j	80003206 <bread+0x40>
    80003200:	68a4                	ld	s1,80(s1)
    80003202:	02e48a63          	beq	s1,a4,80003236 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003206:	449c                	lw	a5,8(s1)
    80003208:	ff279ce3          	bne	a5,s2,80003200 <bread+0x3a>
    8000320c:	44dc                	lw	a5,12(s1)
    8000320e:	ff3799e3          	bne	a5,s3,80003200 <bread+0x3a>
      b->refcnt++;
    80003212:	40bc                	lw	a5,64(s1)
    80003214:	2785                	addiw	a5,a5,1
    80003216:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003218:	00014517          	auipc	a0,0x14
    8000321c:	5b050513          	addi	a0,a0,1456 # 800177c8 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	a6a080e7          	jalr	-1430(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003228:	01048513          	addi	a0,s1,16
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	472080e7          	jalr	1138(ra) # 8000469e <acquiresleep>
      return b;
    80003234:	a8b9                	j	80003292 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003236:	0001d497          	auipc	s1,0x1d
    8000323a:	8424b483          	ld	s1,-1982(s1) # 8001fa78 <bcache+0x82b0>
    8000323e:	0001c797          	auipc	a5,0x1c
    80003242:	7f278793          	addi	a5,a5,2034 # 8001fa30 <bcache+0x8268>
    80003246:	00f48863          	beq	s1,a5,80003256 <bread+0x90>
    8000324a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000324c:	40bc                	lw	a5,64(s1)
    8000324e:	cf81                	beqz	a5,80003266 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003250:	64a4                	ld	s1,72(s1)
    80003252:	fee49de3          	bne	s1,a4,8000324c <bread+0x86>
  panic("bget: no buffers");
    80003256:	00005517          	auipc	a0,0x5
    8000325a:	2da50513          	addi	a0,a0,730 # 80008530 <syscalls+0xe0>
    8000325e:	ffffd097          	auipc	ra,0xffffd
    80003262:	2e2080e7          	jalr	738(ra) # 80000540 <panic>
      b->dev = dev;
    80003266:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000326a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000326e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003272:	4785                	li	a5,1
    80003274:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003276:	00014517          	auipc	a0,0x14
    8000327a:	55250513          	addi	a0,a0,1362 # 800177c8 <bcache>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	a0c080e7          	jalr	-1524(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003286:	01048513          	addi	a0,s1,16
    8000328a:	00001097          	auipc	ra,0x1
    8000328e:	414080e7          	jalr	1044(ra) # 8000469e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003292:	409c                	lw	a5,0(s1)
    80003294:	cb89                	beqz	a5,800032a6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003296:	8526                	mv	a0,s1
    80003298:	70a2                	ld	ra,40(sp)
    8000329a:	7402                	ld	s0,32(sp)
    8000329c:	64e2                	ld	s1,24(sp)
    8000329e:	6942                	ld	s2,16(sp)
    800032a0:	69a2                	ld	s3,8(sp)
    800032a2:	6145                	addi	sp,sp,48
    800032a4:	8082                	ret
    virtio_disk_rw(b, 0);
    800032a6:	4581                	li	a1,0
    800032a8:	8526                	mv	a0,s1
    800032aa:	00003097          	auipc	ra,0x3
    800032ae:	fe8080e7          	jalr	-24(ra) # 80006292 <virtio_disk_rw>
    b->valid = 1;
    800032b2:	4785                	li	a5,1
    800032b4:	c09c                	sw	a5,0(s1)
  return b;
    800032b6:	b7c5                	j	80003296 <bread+0xd0>

00000000800032b8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032b8:	1101                	addi	sp,sp,-32
    800032ba:	ec06                	sd	ra,24(sp)
    800032bc:	e822                	sd	s0,16(sp)
    800032be:	e426                	sd	s1,8(sp)
    800032c0:	1000                	addi	s0,sp,32
    800032c2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032c4:	0541                	addi	a0,a0,16
    800032c6:	00001097          	auipc	ra,0x1
    800032ca:	472080e7          	jalr	1138(ra) # 80004738 <holdingsleep>
    800032ce:	cd01                	beqz	a0,800032e6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032d0:	4585                	li	a1,1
    800032d2:	8526                	mv	a0,s1
    800032d4:	00003097          	auipc	ra,0x3
    800032d8:	fbe080e7          	jalr	-66(ra) # 80006292 <virtio_disk_rw>
}
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	64a2                	ld	s1,8(sp)
    800032e2:	6105                	addi	sp,sp,32
    800032e4:	8082                	ret
    panic("bwrite");
    800032e6:	00005517          	auipc	a0,0x5
    800032ea:	26250513          	addi	a0,a0,610 # 80008548 <syscalls+0xf8>
    800032ee:	ffffd097          	auipc	ra,0xffffd
    800032f2:	252080e7          	jalr	594(ra) # 80000540 <panic>

00000000800032f6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	e426                	sd	s1,8(sp)
    800032fe:	e04a                	sd	s2,0(sp)
    80003300:	1000                	addi	s0,sp,32
    80003302:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003304:	01050913          	addi	s2,a0,16
    80003308:	854a                	mv	a0,s2
    8000330a:	00001097          	auipc	ra,0x1
    8000330e:	42e080e7          	jalr	1070(ra) # 80004738 <holdingsleep>
    80003312:	c92d                	beqz	a0,80003384 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003314:	854a                	mv	a0,s2
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	3de080e7          	jalr	990(ra) # 800046f4 <releasesleep>

  acquire(&bcache.lock);
    8000331e:	00014517          	auipc	a0,0x14
    80003322:	4aa50513          	addi	a0,a0,1194 # 800177c8 <bcache>
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	8b0080e7          	jalr	-1872(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000332e:	40bc                	lw	a5,64(s1)
    80003330:	37fd                	addiw	a5,a5,-1
    80003332:	0007871b          	sext.w	a4,a5
    80003336:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003338:	eb05                	bnez	a4,80003368 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000333a:	68bc                	ld	a5,80(s1)
    8000333c:	64b8                	ld	a4,72(s1)
    8000333e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003340:	64bc                	ld	a5,72(s1)
    80003342:	68b8                	ld	a4,80(s1)
    80003344:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003346:	0001c797          	auipc	a5,0x1c
    8000334a:	48278793          	addi	a5,a5,1154 # 8001f7c8 <bcache+0x8000>
    8000334e:	2b87b703          	ld	a4,696(a5)
    80003352:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003354:	0001c717          	auipc	a4,0x1c
    80003358:	6dc70713          	addi	a4,a4,1756 # 8001fa30 <bcache+0x8268>
    8000335c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000335e:	2b87b703          	ld	a4,696(a5)
    80003362:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003364:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003368:	00014517          	auipc	a0,0x14
    8000336c:	46050513          	addi	a0,a0,1120 # 800177c8 <bcache>
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	91a080e7          	jalr	-1766(ra) # 80000c8a <release>
}
    80003378:	60e2                	ld	ra,24(sp)
    8000337a:	6442                	ld	s0,16(sp)
    8000337c:	64a2                	ld	s1,8(sp)
    8000337e:	6902                	ld	s2,0(sp)
    80003380:	6105                	addi	sp,sp,32
    80003382:	8082                	ret
    panic("brelse");
    80003384:	00005517          	auipc	a0,0x5
    80003388:	1cc50513          	addi	a0,a0,460 # 80008550 <syscalls+0x100>
    8000338c:	ffffd097          	auipc	ra,0xffffd
    80003390:	1b4080e7          	jalr	436(ra) # 80000540 <panic>

0000000080003394 <bpin>:

void
bpin(struct buf *b) {
    80003394:	1101                	addi	sp,sp,-32
    80003396:	ec06                	sd	ra,24(sp)
    80003398:	e822                	sd	s0,16(sp)
    8000339a:	e426                	sd	s1,8(sp)
    8000339c:	1000                	addi	s0,sp,32
    8000339e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033a0:	00014517          	auipc	a0,0x14
    800033a4:	42850513          	addi	a0,a0,1064 # 800177c8 <bcache>
    800033a8:	ffffe097          	auipc	ra,0xffffe
    800033ac:	82e080e7          	jalr	-2002(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800033b0:	40bc                	lw	a5,64(s1)
    800033b2:	2785                	addiw	a5,a5,1
    800033b4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033b6:	00014517          	auipc	a0,0x14
    800033ba:	41250513          	addi	a0,a0,1042 # 800177c8 <bcache>
    800033be:	ffffe097          	auipc	ra,0xffffe
    800033c2:	8cc080e7          	jalr	-1844(ra) # 80000c8a <release>
}
    800033c6:	60e2                	ld	ra,24(sp)
    800033c8:	6442                	ld	s0,16(sp)
    800033ca:	64a2                	ld	s1,8(sp)
    800033cc:	6105                	addi	sp,sp,32
    800033ce:	8082                	ret

00000000800033d0 <bunpin>:

void
bunpin(struct buf *b) {
    800033d0:	1101                	addi	sp,sp,-32
    800033d2:	ec06                	sd	ra,24(sp)
    800033d4:	e822                	sd	s0,16(sp)
    800033d6:	e426                	sd	s1,8(sp)
    800033d8:	1000                	addi	s0,sp,32
    800033da:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033dc:	00014517          	auipc	a0,0x14
    800033e0:	3ec50513          	addi	a0,a0,1004 # 800177c8 <bcache>
    800033e4:	ffffd097          	auipc	ra,0xffffd
    800033e8:	7f2080e7          	jalr	2034(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800033ec:	40bc                	lw	a5,64(s1)
    800033ee:	37fd                	addiw	a5,a5,-1
    800033f0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033f2:	00014517          	auipc	a0,0x14
    800033f6:	3d650513          	addi	a0,a0,982 # 800177c8 <bcache>
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	890080e7          	jalr	-1904(ra) # 80000c8a <release>
}
    80003402:	60e2                	ld	ra,24(sp)
    80003404:	6442                	ld	s0,16(sp)
    80003406:	64a2                	ld	s1,8(sp)
    80003408:	6105                	addi	sp,sp,32
    8000340a:	8082                	ret

000000008000340c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000340c:	1101                	addi	sp,sp,-32
    8000340e:	ec06                	sd	ra,24(sp)
    80003410:	e822                	sd	s0,16(sp)
    80003412:	e426                	sd	s1,8(sp)
    80003414:	e04a                	sd	s2,0(sp)
    80003416:	1000                	addi	s0,sp,32
    80003418:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000341a:	00d5d59b          	srliw	a1,a1,0xd
    8000341e:	0001d797          	auipc	a5,0x1d
    80003422:	a867a783          	lw	a5,-1402(a5) # 8001fea4 <sb+0x1c>
    80003426:	9dbd                	addw	a1,a1,a5
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	d9e080e7          	jalr	-610(ra) # 800031c6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003430:	0074f713          	andi	a4,s1,7
    80003434:	4785                	li	a5,1
    80003436:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000343a:	14ce                	slli	s1,s1,0x33
    8000343c:	90d9                	srli	s1,s1,0x36
    8000343e:	00950733          	add	a4,a0,s1
    80003442:	05874703          	lbu	a4,88(a4)
    80003446:	00e7f6b3          	and	a3,a5,a4
    8000344a:	c69d                	beqz	a3,80003478 <bfree+0x6c>
    8000344c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000344e:	94aa                	add	s1,s1,a0
    80003450:	fff7c793          	not	a5,a5
    80003454:	8f7d                	and	a4,a4,a5
    80003456:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000345a:	00001097          	auipc	ra,0x1
    8000345e:	126080e7          	jalr	294(ra) # 80004580 <log_write>
  brelse(bp);
    80003462:	854a                	mv	a0,s2
    80003464:	00000097          	auipc	ra,0x0
    80003468:	e92080e7          	jalr	-366(ra) # 800032f6 <brelse>
}
    8000346c:	60e2                	ld	ra,24(sp)
    8000346e:	6442                	ld	s0,16(sp)
    80003470:	64a2                	ld	s1,8(sp)
    80003472:	6902                	ld	s2,0(sp)
    80003474:	6105                	addi	sp,sp,32
    80003476:	8082                	ret
    panic("freeing free block");
    80003478:	00005517          	auipc	a0,0x5
    8000347c:	0e050513          	addi	a0,a0,224 # 80008558 <syscalls+0x108>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	0c0080e7          	jalr	192(ra) # 80000540 <panic>

0000000080003488 <balloc>:
{
    80003488:	711d                	addi	sp,sp,-96
    8000348a:	ec86                	sd	ra,88(sp)
    8000348c:	e8a2                	sd	s0,80(sp)
    8000348e:	e4a6                	sd	s1,72(sp)
    80003490:	e0ca                	sd	s2,64(sp)
    80003492:	fc4e                	sd	s3,56(sp)
    80003494:	f852                	sd	s4,48(sp)
    80003496:	f456                	sd	s5,40(sp)
    80003498:	f05a                	sd	s6,32(sp)
    8000349a:	ec5e                	sd	s7,24(sp)
    8000349c:	e862                	sd	s8,16(sp)
    8000349e:	e466                	sd	s9,8(sp)
    800034a0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034a2:	0001d797          	auipc	a5,0x1d
    800034a6:	9ea7a783          	lw	a5,-1558(a5) # 8001fe8c <sb+0x4>
    800034aa:	cff5                	beqz	a5,800035a6 <balloc+0x11e>
    800034ac:	8baa                	mv	s7,a0
    800034ae:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034b0:	0001db17          	auipc	s6,0x1d
    800034b4:	9d8b0b13          	addi	s6,s6,-1576 # 8001fe88 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034ba:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034bc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034be:	6c89                	lui	s9,0x2
    800034c0:	a061                	j	80003548 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034c2:	97ca                	add	a5,a5,s2
    800034c4:	8e55                	or	a2,a2,a3
    800034c6:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800034ca:	854a                	mv	a0,s2
    800034cc:	00001097          	auipc	ra,0x1
    800034d0:	0b4080e7          	jalr	180(ra) # 80004580 <log_write>
        brelse(bp);
    800034d4:	854a                	mv	a0,s2
    800034d6:	00000097          	auipc	ra,0x0
    800034da:	e20080e7          	jalr	-480(ra) # 800032f6 <brelse>
  bp = bread(dev, bno);
    800034de:	85a6                	mv	a1,s1
    800034e0:	855e                	mv	a0,s7
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	ce4080e7          	jalr	-796(ra) # 800031c6 <bread>
    800034ea:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034ec:	40000613          	li	a2,1024
    800034f0:	4581                	li	a1,0
    800034f2:	05850513          	addi	a0,a0,88
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	7dc080e7          	jalr	2012(ra) # 80000cd2 <memset>
  log_write(bp);
    800034fe:	854a                	mv	a0,s2
    80003500:	00001097          	auipc	ra,0x1
    80003504:	080080e7          	jalr	128(ra) # 80004580 <log_write>
  brelse(bp);
    80003508:	854a                	mv	a0,s2
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	dec080e7          	jalr	-532(ra) # 800032f6 <brelse>
}
    80003512:	8526                	mv	a0,s1
    80003514:	60e6                	ld	ra,88(sp)
    80003516:	6446                	ld	s0,80(sp)
    80003518:	64a6                	ld	s1,72(sp)
    8000351a:	6906                	ld	s2,64(sp)
    8000351c:	79e2                	ld	s3,56(sp)
    8000351e:	7a42                	ld	s4,48(sp)
    80003520:	7aa2                	ld	s5,40(sp)
    80003522:	7b02                	ld	s6,32(sp)
    80003524:	6be2                	ld	s7,24(sp)
    80003526:	6c42                	ld	s8,16(sp)
    80003528:	6ca2                	ld	s9,8(sp)
    8000352a:	6125                	addi	sp,sp,96
    8000352c:	8082                	ret
    brelse(bp);
    8000352e:	854a                	mv	a0,s2
    80003530:	00000097          	auipc	ra,0x0
    80003534:	dc6080e7          	jalr	-570(ra) # 800032f6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003538:	015c87bb          	addw	a5,s9,s5
    8000353c:	00078a9b          	sext.w	s5,a5
    80003540:	004b2703          	lw	a4,4(s6)
    80003544:	06eaf163          	bgeu	s5,a4,800035a6 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003548:	41fad79b          	sraiw	a5,s5,0x1f
    8000354c:	0137d79b          	srliw	a5,a5,0x13
    80003550:	015787bb          	addw	a5,a5,s5
    80003554:	40d7d79b          	sraiw	a5,a5,0xd
    80003558:	01cb2583          	lw	a1,28(s6)
    8000355c:	9dbd                	addw	a1,a1,a5
    8000355e:	855e                	mv	a0,s7
    80003560:	00000097          	auipc	ra,0x0
    80003564:	c66080e7          	jalr	-922(ra) # 800031c6 <bread>
    80003568:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000356a:	004b2503          	lw	a0,4(s6)
    8000356e:	000a849b          	sext.w	s1,s5
    80003572:	8762                	mv	a4,s8
    80003574:	faa4fde3          	bgeu	s1,a0,8000352e <balloc+0xa6>
      m = 1 << (bi % 8);
    80003578:	00777693          	andi	a3,a4,7
    8000357c:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003580:	41f7579b          	sraiw	a5,a4,0x1f
    80003584:	01d7d79b          	srliw	a5,a5,0x1d
    80003588:	9fb9                	addw	a5,a5,a4
    8000358a:	4037d79b          	sraiw	a5,a5,0x3
    8000358e:	00f90633          	add	a2,s2,a5
    80003592:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003596:	00c6f5b3          	and	a1,a3,a2
    8000359a:	d585                	beqz	a1,800034c2 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000359c:	2705                	addiw	a4,a4,1
    8000359e:	2485                	addiw	s1,s1,1
    800035a0:	fd471ae3          	bne	a4,s4,80003574 <balloc+0xec>
    800035a4:	b769                	j	8000352e <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800035a6:	00005517          	auipc	a0,0x5
    800035aa:	fca50513          	addi	a0,a0,-54 # 80008570 <syscalls+0x120>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	fdc080e7          	jalr	-36(ra) # 8000058a <printf>
  return 0;
    800035b6:	4481                	li	s1,0
    800035b8:	bfa9                	j	80003512 <balloc+0x8a>

00000000800035ba <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035ba:	7179                	addi	sp,sp,-48
    800035bc:	f406                	sd	ra,40(sp)
    800035be:	f022                	sd	s0,32(sp)
    800035c0:	ec26                	sd	s1,24(sp)
    800035c2:	e84a                	sd	s2,16(sp)
    800035c4:	e44e                	sd	s3,8(sp)
    800035c6:	e052                	sd	s4,0(sp)
    800035c8:	1800                	addi	s0,sp,48
    800035ca:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035cc:	47ad                	li	a5,11
    800035ce:	02b7e863          	bltu	a5,a1,800035fe <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800035d2:	02059793          	slli	a5,a1,0x20
    800035d6:	01e7d593          	srli	a1,a5,0x1e
    800035da:	00b504b3          	add	s1,a0,a1
    800035de:	0504a903          	lw	s2,80(s1)
    800035e2:	06091e63          	bnez	s2,8000365e <bmap+0xa4>
      addr = balloc(ip->dev);
    800035e6:	4108                	lw	a0,0(a0)
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	ea0080e7          	jalr	-352(ra) # 80003488 <balloc>
    800035f0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035f4:	06090563          	beqz	s2,8000365e <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800035f8:	0524a823          	sw	s2,80(s1)
    800035fc:	a08d                	j	8000365e <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800035fe:	ff45849b          	addiw	s1,a1,-12
    80003602:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003606:	0ff00793          	li	a5,255
    8000360a:	08e7e563          	bltu	a5,a4,80003694 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000360e:	08052903          	lw	s2,128(a0)
    80003612:	00091d63          	bnez	s2,8000362c <bmap+0x72>
      addr = balloc(ip->dev);
    80003616:	4108                	lw	a0,0(a0)
    80003618:	00000097          	auipc	ra,0x0
    8000361c:	e70080e7          	jalr	-400(ra) # 80003488 <balloc>
    80003620:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003624:	02090d63          	beqz	s2,8000365e <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003628:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000362c:	85ca                	mv	a1,s2
    8000362e:	0009a503          	lw	a0,0(s3)
    80003632:	00000097          	auipc	ra,0x0
    80003636:	b94080e7          	jalr	-1132(ra) # 800031c6 <bread>
    8000363a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000363c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003640:	02049713          	slli	a4,s1,0x20
    80003644:	01e75593          	srli	a1,a4,0x1e
    80003648:	00b784b3          	add	s1,a5,a1
    8000364c:	0004a903          	lw	s2,0(s1)
    80003650:	02090063          	beqz	s2,80003670 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003654:	8552                	mv	a0,s4
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	ca0080e7          	jalr	-864(ra) # 800032f6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000365e:	854a                	mv	a0,s2
    80003660:	70a2                	ld	ra,40(sp)
    80003662:	7402                	ld	s0,32(sp)
    80003664:	64e2                	ld	s1,24(sp)
    80003666:	6942                	ld	s2,16(sp)
    80003668:	69a2                	ld	s3,8(sp)
    8000366a:	6a02                	ld	s4,0(sp)
    8000366c:	6145                	addi	sp,sp,48
    8000366e:	8082                	ret
      addr = balloc(ip->dev);
    80003670:	0009a503          	lw	a0,0(s3)
    80003674:	00000097          	auipc	ra,0x0
    80003678:	e14080e7          	jalr	-492(ra) # 80003488 <balloc>
    8000367c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003680:	fc090ae3          	beqz	s2,80003654 <bmap+0x9a>
        a[bn] = addr;
    80003684:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003688:	8552                	mv	a0,s4
    8000368a:	00001097          	auipc	ra,0x1
    8000368e:	ef6080e7          	jalr	-266(ra) # 80004580 <log_write>
    80003692:	b7c9                	j	80003654 <bmap+0x9a>
  panic("bmap: out of range");
    80003694:	00005517          	auipc	a0,0x5
    80003698:	ef450513          	addi	a0,a0,-268 # 80008588 <syscalls+0x138>
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	ea4080e7          	jalr	-348(ra) # 80000540 <panic>

00000000800036a4 <iget>:
{
    800036a4:	7179                	addi	sp,sp,-48
    800036a6:	f406                	sd	ra,40(sp)
    800036a8:	f022                	sd	s0,32(sp)
    800036aa:	ec26                	sd	s1,24(sp)
    800036ac:	e84a                	sd	s2,16(sp)
    800036ae:	e44e                	sd	s3,8(sp)
    800036b0:	e052                	sd	s4,0(sp)
    800036b2:	1800                	addi	s0,sp,48
    800036b4:	89aa                	mv	s3,a0
    800036b6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036b8:	0001c517          	auipc	a0,0x1c
    800036bc:	7f050513          	addi	a0,a0,2032 # 8001fea8 <itable>
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	516080e7          	jalr	1302(ra) # 80000bd6 <acquire>
  empty = 0;
    800036c8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036ca:	0001c497          	auipc	s1,0x1c
    800036ce:	7f648493          	addi	s1,s1,2038 # 8001fec0 <itable+0x18>
    800036d2:	0001e697          	auipc	a3,0x1e
    800036d6:	27e68693          	addi	a3,a3,638 # 80021950 <log>
    800036da:	a039                	j	800036e8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036dc:	02090b63          	beqz	s2,80003712 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036e0:	08848493          	addi	s1,s1,136
    800036e4:	02d48a63          	beq	s1,a3,80003718 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036e8:	449c                	lw	a5,8(s1)
    800036ea:	fef059e3          	blez	a5,800036dc <iget+0x38>
    800036ee:	4098                	lw	a4,0(s1)
    800036f0:	ff3716e3          	bne	a4,s3,800036dc <iget+0x38>
    800036f4:	40d8                	lw	a4,4(s1)
    800036f6:	ff4713e3          	bne	a4,s4,800036dc <iget+0x38>
      ip->ref++;
    800036fa:	2785                	addiw	a5,a5,1
    800036fc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036fe:	0001c517          	auipc	a0,0x1c
    80003702:	7aa50513          	addi	a0,a0,1962 # 8001fea8 <itable>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	584080e7          	jalr	1412(ra) # 80000c8a <release>
      return ip;
    8000370e:	8926                	mv	s2,s1
    80003710:	a03d                	j	8000373e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003712:	f7f9                	bnez	a5,800036e0 <iget+0x3c>
    80003714:	8926                	mv	s2,s1
    80003716:	b7e9                	j	800036e0 <iget+0x3c>
  if(empty == 0)
    80003718:	02090c63          	beqz	s2,80003750 <iget+0xac>
  ip->dev = dev;
    8000371c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003720:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003724:	4785                	li	a5,1
    80003726:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000372a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000372e:	0001c517          	auipc	a0,0x1c
    80003732:	77a50513          	addi	a0,a0,1914 # 8001fea8 <itable>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	554080e7          	jalr	1364(ra) # 80000c8a <release>
}
    8000373e:	854a                	mv	a0,s2
    80003740:	70a2                	ld	ra,40(sp)
    80003742:	7402                	ld	s0,32(sp)
    80003744:	64e2                	ld	s1,24(sp)
    80003746:	6942                	ld	s2,16(sp)
    80003748:	69a2                	ld	s3,8(sp)
    8000374a:	6a02                	ld	s4,0(sp)
    8000374c:	6145                	addi	sp,sp,48
    8000374e:	8082                	ret
    panic("iget: no inodes");
    80003750:	00005517          	auipc	a0,0x5
    80003754:	e5050513          	addi	a0,a0,-432 # 800085a0 <syscalls+0x150>
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	de8080e7          	jalr	-536(ra) # 80000540 <panic>

0000000080003760 <fsinit>:
fsinit(int dev) {
    80003760:	7179                	addi	sp,sp,-48
    80003762:	f406                	sd	ra,40(sp)
    80003764:	f022                	sd	s0,32(sp)
    80003766:	ec26                	sd	s1,24(sp)
    80003768:	e84a                	sd	s2,16(sp)
    8000376a:	e44e                	sd	s3,8(sp)
    8000376c:	1800                	addi	s0,sp,48
    8000376e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003770:	4585                	li	a1,1
    80003772:	00000097          	auipc	ra,0x0
    80003776:	a54080e7          	jalr	-1452(ra) # 800031c6 <bread>
    8000377a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000377c:	0001c997          	auipc	s3,0x1c
    80003780:	70c98993          	addi	s3,s3,1804 # 8001fe88 <sb>
    80003784:	02000613          	li	a2,32
    80003788:	05850593          	addi	a1,a0,88
    8000378c:	854e                	mv	a0,s3
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	5a0080e7          	jalr	1440(ra) # 80000d2e <memmove>
  brelse(bp);
    80003796:	8526                	mv	a0,s1
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	b5e080e7          	jalr	-1186(ra) # 800032f6 <brelse>
  if(sb.magic != FSMAGIC)
    800037a0:	0009a703          	lw	a4,0(s3)
    800037a4:	102037b7          	lui	a5,0x10203
    800037a8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037ac:	02f71263          	bne	a4,a5,800037d0 <fsinit+0x70>
  initlog(dev, &sb);
    800037b0:	0001c597          	auipc	a1,0x1c
    800037b4:	6d858593          	addi	a1,a1,1752 # 8001fe88 <sb>
    800037b8:	854a                	mv	a0,s2
    800037ba:	00001097          	auipc	ra,0x1
    800037be:	b4a080e7          	jalr	-1206(ra) # 80004304 <initlog>
}
    800037c2:	70a2                	ld	ra,40(sp)
    800037c4:	7402                	ld	s0,32(sp)
    800037c6:	64e2                	ld	s1,24(sp)
    800037c8:	6942                	ld	s2,16(sp)
    800037ca:	69a2                	ld	s3,8(sp)
    800037cc:	6145                	addi	sp,sp,48
    800037ce:	8082                	ret
    panic("invalid file system");
    800037d0:	00005517          	auipc	a0,0x5
    800037d4:	de050513          	addi	a0,a0,-544 # 800085b0 <syscalls+0x160>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	d68080e7          	jalr	-664(ra) # 80000540 <panic>

00000000800037e0 <iinit>:
{
    800037e0:	7179                	addi	sp,sp,-48
    800037e2:	f406                	sd	ra,40(sp)
    800037e4:	f022                	sd	s0,32(sp)
    800037e6:	ec26                	sd	s1,24(sp)
    800037e8:	e84a                	sd	s2,16(sp)
    800037ea:	e44e                	sd	s3,8(sp)
    800037ec:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037ee:	00005597          	auipc	a1,0x5
    800037f2:	dda58593          	addi	a1,a1,-550 # 800085c8 <syscalls+0x178>
    800037f6:	0001c517          	auipc	a0,0x1c
    800037fa:	6b250513          	addi	a0,a0,1714 # 8001fea8 <itable>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	348080e7          	jalr	840(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003806:	0001c497          	auipc	s1,0x1c
    8000380a:	6ca48493          	addi	s1,s1,1738 # 8001fed0 <itable+0x28>
    8000380e:	0001e997          	auipc	s3,0x1e
    80003812:	15298993          	addi	s3,s3,338 # 80021960 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003816:	00005917          	auipc	s2,0x5
    8000381a:	dba90913          	addi	s2,s2,-582 # 800085d0 <syscalls+0x180>
    8000381e:	85ca                	mv	a1,s2
    80003820:	8526                	mv	a0,s1
    80003822:	00001097          	auipc	ra,0x1
    80003826:	e42080e7          	jalr	-446(ra) # 80004664 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000382a:	08848493          	addi	s1,s1,136
    8000382e:	ff3498e3          	bne	s1,s3,8000381e <iinit+0x3e>
}
    80003832:	70a2                	ld	ra,40(sp)
    80003834:	7402                	ld	s0,32(sp)
    80003836:	64e2                	ld	s1,24(sp)
    80003838:	6942                	ld	s2,16(sp)
    8000383a:	69a2                	ld	s3,8(sp)
    8000383c:	6145                	addi	sp,sp,48
    8000383e:	8082                	ret

0000000080003840 <ialloc>:
{
    80003840:	715d                	addi	sp,sp,-80
    80003842:	e486                	sd	ra,72(sp)
    80003844:	e0a2                	sd	s0,64(sp)
    80003846:	fc26                	sd	s1,56(sp)
    80003848:	f84a                	sd	s2,48(sp)
    8000384a:	f44e                	sd	s3,40(sp)
    8000384c:	f052                	sd	s4,32(sp)
    8000384e:	ec56                	sd	s5,24(sp)
    80003850:	e85a                	sd	s6,16(sp)
    80003852:	e45e                	sd	s7,8(sp)
    80003854:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003856:	0001c717          	auipc	a4,0x1c
    8000385a:	63e72703          	lw	a4,1598(a4) # 8001fe94 <sb+0xc>
    8000385e:	4785                	li	a5,1
    80003860:	04e7fa63          	bgeu	a5,a4,800038b4 <ialloc+0x74>
    80003864:	8aaa                	mv	s5,a0
    80003866:	8bae                	mv	s7,a1
    80003868:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000386a:	0001ca17          	auipc	s4,0x1c
    8000386e:	61ea0a13          	addi	s4,s4,1566 # 8001fe88 <sb>
    80003872:	00048b1b          	sext.w	s6,s1
    80003876:	0044d593          	srli	a1,s1,0x4
    8000387a:	018a2783          	lw	a5,24(s4)
    8000387e:	9dbd                	addw	a1,a1,a5
    80003880:	8556                	mv	a0,s5
    80003882:	00000097          	auipc	ra,0x0
    80003886:	944080e7          	jalr	-1724(ra) # 800031c6 <bread>
    8000388a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000388c:	05850993          	addi	s3,a0,88
    80003890:	00f4f793          	andi	a5,s1,15
    80003894:	079a                	slli	a5,a5,0x6
    80003896:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003898:	00099783          	lh	a5,0(s3)
    8000389c:	c3a1                	beqz	a5,800038dc <ialloc+0x9c>
    brelse(bp);
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	a58080e7          	jalr	-1448(ra) # 800032f6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038a6:	0485                	addi	s1,s1,1
    800038a8:	00ca2703          	lw	a4,12(s4)
    800038ac:	0004879b          	sext.w	a5,s1
    800038b0:	fce7e1e3          	bltu	a5,a4,80003872 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800038b4:	00005517          	auipc	a0,0x5
    800038b8:	d2450513          	addi	a0,a0,-732 # 800085d8 <syscalls+0x188>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	cce080e7          	jalr	-818(ra) # 8000058a <printf>
  return 0;
    800038c4:	4501                	li	a0,0
}
    800038c6:	60a6                	ld	ra,72(sp)
    800038c8:	6406                	ld	s0,64(sp)
    800038ca:	74e2                	ld	s1,56(sp)
    800038cc:	7942                	ld	s2,48(sp)
    800038ce:	79a2                	ld	s3,40(sp)
    800038d0:	7a02                	ld	s4,32(sp)
    800038d2:	6ae2                	ld	s5,24(sp)
    800038d4:	6b42                	ld	s6,16(sp)
    800038d6:	6ba2                	ld	s7,8(sp)
    800038d8:	6161                	addi	sp,sp,80
    800038da:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038dc:	04000613          	li	a2,64
    800038e0:	4581                	li	a1,0
    800038e2:	854e                	mv	a0,s3
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	3ee080e7          	jalr	1006(ra) # 80000cd2 <memset>
      dip->type = type;
    800038ec:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038f0:	854a                	mv	a0,s2
    800038f2:	00001097          	auipc	ra,0x1
    800038f6:	c8e080e7          	jalr	-882(ra) # 80004580 <log_write>
      brelse(bp);
    800038fa:	854a                	mv	a0,s2
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	9fa080e7          	jalr	-1542(ra) # 800032f6 <brelse>
      return iget(dev, inum);
    80003904:	85da                	mv	a1,s6
    80003906:	8556                	mv	a0,s5
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	d9c080e7          	jalr	-612(ra) # 800036a4 <iget>
    80003910:	bf5d                	j	800038c6 <ialloc+0x86>

0000000080003912 <iupdate>:
{
    80003912:	1101                	addi	sp,sp,-32
    80003914:	ec06                	sd	ra,24(sp)
    80003916:	e822                	sd	s0,16(sp)
    80003918:	e426                	sd	s1,8(sp)
    8000391a:	e04a                	sd	s2,0(sp)
    8000391c:	1000                	addi	s0,sp,32
    8000391e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003920:	415c                	lw	a5,4(a0)
    80003922:	0047d79b          	srliw	a5,a5,0x4
    80003926:	0001c597          	auipc	a1,0x1c
    8000392a:	57a5a583          	lw	a1,1402(a1) # 8001fea0 <sb+0x18>
    8000392e:	9dbd                	addw	a1,a1,a5
    80003930:	4108                	lw	a0,0(a0)
    80003932:	00000097          	auipc	ra,0x0
    80003936:	894080e7          	jalr	-1900(ra) # 800031c6 <bread>
    8000393a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000393c:	05850793          	addi	a5,a0,88
    80003940:	40d8                	lw	a4,4(s1)
    80003942:	8b3d                	andi	a4,a4,15
    80003944:	071a                	slli	a4,a4,0x6
    80003946:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003948:	04449703          	lh	a4,68(s1)
    8000394c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003950:	04649703          	lh	a4,70(s1)
    80003954:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003958:	04849703          	lh	a4,72(s1)
    8000395c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003960:	04a49703          	lh	a4,74(s1)
    80003964:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003968:	44f8                	lw	a4,76(s1)
    8000396a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000396c:	03400613          	li	a2,52
    80003970:	05048593          	addi	a1,s1,80
    80003974:	00c78513          	addi	a0,a5,12
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	3b6080e7          	jalr	950(ra) # 80000d2e <memmove>
  log_write(bp);
    80003980:	854a                	mv	a0,s2
    80003982:	00001097          	auipc	ra,0x1
    80003986:	bfe080e7          	jalr	-1026(ra) # 80004580 <log_write>
  brelse(bp);
    8000398a:	854a                	mv	a0,s2
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	96a080e7          	jalr	-1686(ra) # 800032f6 <brelse>
}
    80003994:	60e2                	ld	ra,24(sp)
    80003996:	6442                	ld	s0,16(sp)
    80003998:	64a2                	ld	s1,8(sp)
    8000399a:	6902                	ld	s2,0(sp)
    8000399c:	6105                	addi	sp,sp,32
    8000399e:	8082                	ret

00000000800039a0 <idup>:
{
    800039a0:	1101                	addi	sp,sp,-32
    800039a2:	ec06                	sd	ra,24(sp)
    800039a4:	e822                	sd	s0,16(sp)
    800039a6:	e426                	sd	s1,8(sp)
    800039a8:	1000                	addi	s0,sp,32
    800039aa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039ac:	0001c517          	auipc	a0,0x1c
    800039b0:	4fc50513          	addi	a0,a0,1276 # 8001fea8 <itable>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	222080e7          	jalr	546(ra) # 80000bd6 <acquire>
  ip->ref++;
    800039bc:	449c                	lw	a5,8(s1)
    800039be:	2785                	addiw	a5,a5,1
    800039c0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039c2:	0001c517          	auipc	a0,0x1c
    800039c6:	4e650513          	addi	a0,a0,1254 # 8001fea8 <itable>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	2c0080e7          	jalr	704(ra) # 80000c8a <release>
}
    800039d2:	8526                	mv	a0,s1
    800039d4:	60e2                	ld	ra,24(sp)
    800039d6:	6442                	ld	s0,16(sp)
    800039d8:	64a2                	ld	s1,8(sp)
    800039da:	6105                	addi	sp,sp,32
    800039dc:	8082                	ret

00000000800039de <ilock>:
{
    800039de:	1101                	addi	sp,sp,-32
    800039e0:	ec06                	sd	ra,24(sp)
    800039e2:	e822                	sd	s0,16(sp)
    800039e4:	e426                	sd	s1,8(sp)
    800039e6:	e04a                	sd	s2,0(sp)
    800039e8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039ea:	c115                	beqz	a0,80003a0e <ilock+0x30>
    800039ec:	84aa                	mv	s1,a0
    800039ee:	451c                	lw	a5,8(a0)
    800039f0:	00f05f63          	blez	a5,80003a0e <ilock+0x30>
  acquiresleep(&ip->lock);
    800039f4:	0541                	addi	a0,a0,16
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	ca8080e7          	jalr	-856(ra) # 8000469e <acquiresleep>
  if(ip->valid == 0){
    800039fe:	40bc                	lw	a5,64(s1)
    80003a00:	cf99                	beqz	a5,80003a1e <ilock+0x40>
}
    80003a02:	60e2                	ld	ra,24(sp)
    80003a04:	6442                	ld	s0,16(sp)
    80003a06:	64a2                	ld	s1,8(sp)
    80003a08:	6902                	ld	s2,0(sp)
    80003a0a:	6105                	addi	sp,sp,32
    80003a0c:	8082                	ret
    panic("ilock");
    80003a0e:	00005517          	auipc	a0,0x5
    80003a12:	be250513          	addi	a0,a0,-1054 # 800085f0 <syscalls+0x1a0>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	b2a080e7          	jalr	-1238(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a1e:	40dc                	lw	a5,4(s1)
    80003a20:	0047d79b          	srliw	a5,a5,0x4
    80003a24:	0001c597          	auipc	a1,0x1c
    80003a28:	47c5a583          	lw	a1,1148(a1) # 8001fea0 <sb+0x18>
    80003a2c:	9dbd                	addw	a1,a1,a5
    80003a2e:	4088                	lw	a0,0(s1)
    80003a30:	fffff097          	auipc	ra,0xfffff
    80003a34:	796080e7          	jalr	1942(ra) # 800031c6 <bread>
    80003a38:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a3a:	05850593          	addi	a1,a0,88
    80003a3e:	40dc                	lw	a5,4(s1)
    80003a40:	8bbd                	andi	a5,a5,15
    80003a42:	079a                	slli	a5,a5,0x6
    80003a44:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a46:	00059783          	lh	a5,0(a1)
    80003a4a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a4e:	00259783          	lh	a5,2(a1)
    80003a52:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a56:	00459783          	lh	a5,4(a1)
    80003a5a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a5e:	00659783          	lh	a5,6(a1)
    80003a62:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a66:	459c                	lw	a5,8(a1)
    80003a68:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a6a:	03400613          	li	a2,52
    80003a6e:	05b1                	addi	a1,a1,12
    80003a70:	05048513          	addi	a0,s1,80
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	2ba080e7          	jalr	698(ra) # 80000d2e <memmove>
    brelse(bp);
    80003a7c:	854a                	mv	a0,s2
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	878080e7          	jalr	-1928(ra) # 800032f6 <brelse>
    ip->valid = 1;
    80003a86:	4785                	li	a5,1
    80003a88:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a8a:	04449783          	lh	a5,68(s1)
    80003a8e:	fbb5                	bnez	a5,80003a02 <ilock+0x24>
      panic("ilock: no type");
    80003a90:	00005517          	auipc	a0,0x5
    80003a94:	b6850513          	addi	a0,a0,-1176 # 800085f8 <syscalls+0x1a8>
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	aa8080e7          	jalr	-1368(ra) # 80000540 <panic>

0000000080003aa0 <iunlock>:
{
    80003aa0:	1101                	addi	sp,sp,-32
    80003aa2:	ec06                	sd	ra,24(sp)
    80003aa4:	e822                	sd	s0,16(sp)
    80003aa6:	e426                	sd	s1,8(sp)
    80003aa8:	e04a                	sd	s2,0(sp)
    80003aaa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003aac:	c905                	beqz	a0,80003adc <iunlock+0x3c>
    80003aae:	84aa                	mv	s1,a0
    80003ab0:	01050913          	addi	s2,a0,16
    80003ab4:	854a                	mv	a0,s2
    80003ab6:	00001097          	auipc	ra,0x1
    80003aba:	c82080e7          	jalr	-894(ra) # 80004738 <holdingsleep>
    80003abe:	cd19                	beqz	a0,80003adc <iunlock+0x3c>
    80003ac0:	449c                	lw	a5,8(s1)
    80003ac2:	00f05d63          	blez	a5,80003adc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ac6:	854a                	mv	a0,s2
    80003ac8:	00001097          	auipc	ra,0x1
    80003acc:	c2c080e7          	jalr	-980(ra) # 800046f4 <releasesleep>
}
    80003ad0:	60e2                	ld	ra,24(sp)
    80003ad2:	6442                	ld	s0,16(sp)
    80003ad4:	64a2                	ld	s1,8(sp)
    80003ad6:	6902                	ld	s2,0(sp)
    80003ad8:	6105                	addi	sp,sp,32
    80003ada:	8082                	ret
    panic("iunlock");
    80003adc:	00005517          	auipc	a0,0x5
    80003ae0:	b2c50513          	addi	a0,a0,-1236 # 80008608 <syscalls+0x1b8>
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	a5c080e7          	jalr	-1444(ra) # 80000540 <panic>

0000000080003aec <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003aec:	7179                	addi	sp,sp,-48
    80003aee:	f406                	sd	ra,40(sp)
    80003af0:	f022                	sd	s0,32(sp)
    80003af2:	ec26                	sd	s1,24(sp)
    80003af4:	e84a                	sd	s2,16(sp)
    80003af6:	e44e                	sd	s3,8(sp)
    80003af8:	e052                	sd	s4,0(sp)
    80003afa:	1800                	addi	s0,sp,48
    80003afc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003afe:	05050493          	addi	s1,a0,80
    80003b02:	08050913          	addi	s2,a0,128
    80003b06:	a021                	j	80003b0e <itrunc+0x22>
    80003b08:	0491                	addi	s1,s1,4
    80003b0a:	01248d63          	beq	s1,s2,80003b24 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b0e:	408c                	lw	a1,0(s1)
    80003b10:	dde5                	beqz	a1,80003b08 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b12:	0009a503          	lw	a0,0(s3)
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	8f6080e7          	jalr	-1802(ra) # 8000340c <bfree>
      ip->addrs[i] = 0;
    80003b1e:	0004a023          	sw	zero,0(s1)
    80003b22:	b7dd                	j	80003b08 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b24:	0809a583          	lw	a1,128(s3)
    80003b28:	e185                	bnez	a1,80003b48 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b2a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b2e:	854e                	mv	a0,s3
    80003b30:	00000097          	auipc	ra,0x0
    80003b34:	de2080e7          	jalr	-542(ra) # 80003912 <iupdate>
}
    80003b38:	70a2                	ld	ra,40(sp)
    80003b3a:	7402                	ld	s0,32(sp)
    80003b3c:	64e2                	ld	s1,24(sp)
    80003b3e:	6942                	ld	s2,16(sp)
    80003b40:	69a2                	ld	s3,8(sp)
    80003b42:	6a02                	ld	s4,0(sp)
    80003b44:	6145                	addi	sp,sp,48
    80003b46:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b48:	0009a503          	lw	a0,0(s3)
    80003b4c:	fffff097          	auipc	ra,0xfffff
    80003b50:	67a080e7          	jalr	1658(ra) # 800031c6 <bread>
    80003b54:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b56:	05850493          	addi	s1,a0,88
    80003b5a:	45850913          	addi	s2,a0,1112
    80003b5e:	a021                	j	80003b66 <itrunc+0x7a>
    80003b60:	0491                	addi	s1,s1,4
    80003b62:	01248b63          	beq	s1,s2,80003b78 <itrunc+0x8c>
      if(a[j])
    80003b66:	408c                	lw	a1,0(s1)
    80003b68:	dde5                	beqz	a1,80003b60 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b6a:	0009a503          	lw	a0,0(s3)
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	89e080e7          	jalr	-1890(ra) # 8000340c <bfree>
    80003b76:	b7ed                	j	80003b60 <itrunc+0x74>
    brelse(bp);
    80003b78:	8552                	mv	a0,s4
    80003b7a:	fffff097          	auipc	ra,0xfffff
    80003b7e:	77c080e7          	jalr	1916(ra) # 800032f6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b82:	0809a583          	lw	a1,128(s3)
    80003b86:	0009a503          	lw	a0,0(s3)
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	882080e7          	jalr	-1918(ra) # 8000340c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b92:	0809a023          	sw	zero,128(s3)
    80003b96:	bf51                	j	80003b2a <itrunc+0x3e>

0000000080003b98 <iput>:
{
    80003b98:	1101                	addi	sp,sp,-32
    80003b9a:	ec06                	sd	ra,24(sp)
    80003b9c:	e822                	sd	s0,16(sp)
    80003b9e:	e426                	sd	s1,8(sp)
    80003ba0:	e04a                	sd	s2,0(sp)
    80003ba2:	1000                	addi	s0,sp,32
    80003ba4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ba6:	0001c517          	auipc	a0,0x1c
    80003baa:	30250513          	addi	a0,a0,770 # 8001fea8 <itable>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	028080e7          	jalr	40(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bb6:	4498                	lw	a4,8(s1)
    80003bb8:	4785                	li	a5,1
    80003bba:	02f70363          	beq	a4,a5,80003be0 <iput+0x48>
  ip->ref--;
    80003bbe:	449c                	lw	a5,8(s1)
    80003bc0:	37fd                	addiw	a5,a5,-1
    80003bc2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bc4:	0001c517          	auipc	a0,0x1c
    80003bc8:	2e450513          	addi	a0,a0,740 # 8001fea8 <itable>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	0be080e7          	jalr	190(ra) # 80000c8a <release>
}
    80003bd4:	60e2                	ld	ra,24(sp)
    80003bd6:	6442                	ld	s0,16(sp)
    80003bd8:	64a2                	ld	s1,8(sp)
    80003bda:	6902                	ld	s2,0(sp)
    80003bdc:	6105                	addi	sp,sp,32
    80003bde:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003be0:	40bc                	lw	a5,64(s1)
    80003be2:	dff1                	beqz	a5,80003bbe <iput+0x26>
    80003be4:	04a49783          	lh	a5,74(s1)
    80003be8:	fbf9                	bnez	a5,80003bbe <iput+0x26>
    acquiresleep(&ip->lock);
    80003bea:	01048913          	addi	s2,s1,16
    80003bee:	854a                	mv	a0,s2
    80003bf0:	00001097          	auipc	ra,0x1
    80003bf4:	aae080e7          	jalr	-1362(ra) # 8000469e <acquiresleep>
    release(&itable.lock);
    80003bf8:	0001c517          	auipc	a0,0x1c
    80003bfc:	2b050513          	addi	a0,a0,688 # 8001fea8 <itable>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	08a080e7          	jalr	138(ra) # 80000c8a <release>
    itrunc(ip);
    80003c08:	8526                	mv	a0,s1
    80003c0a:	00000097          	auipc	ra,0x0
    80003c0e:	ee2080e7          	jalr	-286(ra) # 80003aec <itrunc>
    ip->type = 0;
    80003c12:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c16:	8526                	mv	a0,s1
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	cfa080e7          	jalr	-774(ra) # 80003912 <iupdate>
    ip->valid = 0;
    80003c20:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c24:	854a                	mv	a0,s2
    80003c26:	00001097          	auipc	ra,0x1
    80003c2a:	ace080e7          	jalr	-1330(ra) # 800046f4 <releasesleep>
    acquire(&itable.lock);
    80003c2e:	0001c517          	auipc	a0,0x1c
    80003c32:	27a50513          	addi	a0,a0,634 # 8001fea8 <itable>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	fa0080e7          	jalr	-96(ra) # 80000bd6 <acquire>
    80003c3e:	b741                	j	80003bbe <iput+0x26>

0000000080003c40 <iunlockput>:
{
    80003c40:	1101                	addi	sp,sp,-32
    80003c42:	ec06                	sd	ra,24(sp)
    80003c44:	e822                	sd	s0,16(sp)
    80003c46:	e426                	sd	s1,8(sp)
    80003c48:	1000                	addi	s0,sp,32
    80003c4a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	e54080e7          	jalr	-428(ra) # 80003aa0 <iunlock>
  iput(ip);
    80003c54:	8526                	mv	a0,s1
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	f42080e7          	jalr	-190(ra) # 80003b98 <iput>
}
    80003c5e:	60e2                	ld	ra,24(sp)
    80003c60:	6442                	ld	s0,16(sp)
    80003c62:	64a2                	ld	s1,8(sp)
    80003c64:	6105                	addi	sp,sp,32
    80003c66:	8082                	ret

0000000080003c68 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c68:	1141                	addi	sp,sp,-16
    80003c6a:	e422                	sd	s0,8(sp)
    80003c6c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c6e:	411c                	lw	a5,0(a0)
    80003c70:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c72:	415c                	lw	a5,4(a0)
    80003c74:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c76:	04451783          	lh	a5,68(a0)
    80003c7a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c7e:	04a51783          	lh	a5,74(a0)
    80003c82:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c86:	04c56783          	lwu	a5,76(a0)
    80003c8a:	e99c                	sd	a5,16(a1)
}
    80003c8c:	6422                	ld	s0,8(sp)
    80003c8e:	0141                	addi	sp,sp,16
    80003c90:	8082                	ret

0000000080003c92 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c92:	457c                	lw	a5,76(a0)
    80003c94:	0ed7e963          	bltu	a5,a3,80003d86 <readi+0xf4>
{
    80003c98:	7159                	addi	sp,sp,-112
    80003c9a:	f486                	sd	ra,104(sp)
    80003c9c:	f0a2                	sd	s0,96(sp)
    80003c9e:	eca6                	sd	s1,88(sp)
    80003ca0:	e8ca                	sd	s2,80(sp)
    80003ca2:	e4ce                	sd	s3,72(sp)
    80003ca4:	e0d2                	sd	s4,64(sp)
    80003ca6:	fc56                	sd	s5,56(sp)
    80003ca8:	f85a                	sd	s6,48(sp)
    80003caa:	f45e                	sd	s7,40(sp)
    80003cac:	f062                	sd	s8,32(sp)
    80003cae:	ec66                	sd	s9,24(sp)
    80003cb0:	e86a                	sd	s10,16(sp)
    80003cb2:	e46e                	sd	s11,8(sp)
    80003cb4:	1880                	addi	s0,sp,112
    80003cb6:	8b2a                	mv	s6,a0
    80003cb8:	8bae                	mv	s7,a1
    80003cba:	8a32                	mv	s4,a2
    80003cbc:	84b6                	mv	s1,a3
    80003cbe:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003cc0:	9f35                	addw	a4,a4,a3
    return 0;
    80003cc2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cc4:	0ad76063          	bltu	a4,a3,80003d64 <readi+0xd2>
  if(off + n > ip->size)
    80003cc8:	00e7f463          	bgeu	a5,a4,80003cd0 <readi+0x3e>
    n = ip->size - off;
    80003ccc:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd0:	0a0a8963          	beqz	s5,80003d82 <readi+0xf0>
    80003cd4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cda:	5c7d                	li	s8,-1
    80003cdc:	a82d                	j	80003d16 <readi+0x84>
    80003cde:	020d1d93          	slli	s11,s10,0x20
    80003ce2:	020ddd93          	srli	s11,s11,0x20
    80003ce6:	05890613          	addi	a2,s2,88
    80003cea:	86ee                	mv	a3,s11
    80003cec:	963a                	add	a2,a2,a4
    80003cee:	85d2                	mv	a1,s4
    80003cf0:	855e                	mv	a0,s7
    80003cf2:	ffffe097          	auipc	ra,0xffffe
    80003cf6:	79a080e7          	jalr	1946(ra) # 8000248c <either_copyout>
    80003cfa:	05850d63          	beq	a0,s8,80003d54 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cfe:	854a                	mv	a0,s2
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	5f6080e7          	jalr	1526(ra) # 800032f6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d08:	013d09bb          	addw	s3,s10,s3
    80003d0c:	009d04bb          	addw	s1,s10,s1
    80003d10:	9a6e                	add	s4,s4,s11
    80003d12:	0559f763          	bgeu	s3,s5,80003d60 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d16:	00a4d59b          	srliw	a1,s1,0xa
    80003d1a:	855a                	mv	a0,s6
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	89e080e7          	jalr	-1890(ra) # 800035ba <bmap>
    80003d24:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d28:	cd85                	beqz	a1,80003d60 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d2a:	000b2503          	lw	a0,0(s6)
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	498080e7          	jalr	1176(ra) # 800031c6 <bread>
    80003d36:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d38:	3ff4f713          	andi	a4,s1,1023
    80003d3c:	40ec87bb          	subw	a5,s9,a4
    80003d40:	413a86bb          	subw	a3,s5,s3
    80003d44:	8d3e                	mv	s10,a5
    80003d46:	2781                	sext.w	a5,a5
    80003d48:	0006861b          	sext.w	a2,a3
    80003d4c:	f8f679e3          	bgeu	a2,a5,80003cde <readi+0x4c>
    80003d50:	8d36                	mv	s10,a3
    80003d52:	b771                	j	80003cde <readi+0x4c>
      brelse(bp);
    80003d54:	854a                	mv	a0,s2
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	5a0080e7          	jalr	1440(ra) # 800032f6 <brelse>
      tot = -1;
    80003d5e:	59fd                	li	s3,-1
  }
  return tot;
    80003d60:	0009851b          	sext.w	a0,s3
}
    80003d64:	70a6                	ld	ra,104(sp)
    80003d66:	7406                	ld	s0,96(sp)
    80003d68:	64e6                	ld	s1,88(sp)
    80003d6a:	6946                	ld	s2,80(sp)
    80003d6c:	69a6                	ld	s3,72(sp)
    80003d6e:	6a06                	ld	s4,64(sp)
    80003d70:	7ae2                	ld	s5,56(sp)
    80003d72:	7b42                	ld	s6,48(sp)
    80003d74:	7ba2                	ld	s7,40(sp)
    80003d76:	7c02                	ld	s8,32(sp)
    80003d78:	6ce2                	ld	s9,24(sp)
    80003d7a:	6d42                	ld	s10,16(sp)
    80003d7c:	6da2                	ld	s11,8(sp)
    80003d7e:	6165                	addi	sp,sp,112
    80003d80:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d82:	89d6                	mv	s3,s5
    80003d84:	bff1                	j	80003d60 <readi+0xce>
    return 0;
    80003d86:	4501                	li	a0,0
}
    80003d88:	8082                	ret

0000000080003d8a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d8a:	457c                	lw	a5,76(a0)
    80003d8c:	10d7e863          	bltu	a5,a3,80003e9c <writei+0x112>
{
    80003d90:	7159                	addi	sp,sp,-112
    80003d92:	f486                	sd	ra,104(sp)
    80003d94:	f0a2                	sd	s0,96(sp)
    80003d96:	eca6                	sd	s1,88(sp)
    80003d98:	e8ca                	sd	s2,80(sp)
    80003d9a:	e4ce                	sd	s3,72(sp)
    80003d9c:	e0d2                	sd	s4,64(sp)
    80003d9e:	fc56                	sd	s5,56(sp)
    80003da0:	f85a                	sd	s6,48(sp)
    80003da2:	f45e                	sd	s7,40(sp)
    80003da4:	f062                	sd	s8,32(sp)
    80003da6:	ec66                	sd	s9,24(sp)
    80003da8:	e86a                	sd	s10,16(sp)
    80003daa:	e46e                	sd	s11,8(sp)
    80003dac:	1880                	addi	s0,sp,112
    80003dae:	8aaa                	mv	s5,a0
    80003db0:	8bae                	mv	s7,a1
    80003db2:	8a32                	mv	s4,a2
    80003db4:	8936                	mv	s2,a3
    80003db6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003db8:	00e687bb          	addw	a5,a3,a4
    80003dbc:	0ed7e263          	bltu	a5,a3,80003ea0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003dc0:	00043737          	lui	a4,0x43
    80003dc4:	0ef76063          	bltu	a4,a5,80003ea4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dc8:	0c0b0863          	beqz	s6,80003e98 <writei+0x10e>
    80003dcc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dce:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dd2:	5c7d                	li	s8,-1
    80003dd4:	a091                	j	80003e18 <writei+0x8e>
    80003dd6:	020d1d93          	slli	s11,s10,0x20
    80003dda:	020ddd93          	srli	s11,s11,0x20
    80003dde:	05848513          	addi	a0,s1,88
    80003de2:	86ee                	mv	a3,s11
    80003de4:	8652                	mv	a2,s4
    80003de6:	85de                	mv	a1,s7
    80003de8:	953a                	add	a0,a0,a4
    80003dea:	ffffe097          	auipc	ra,0xffffe
    80003dee:	6f8080e7          	jalr	1784(ra) # 800024e2 <either_copyin>
    80003df2:	07850263          	beq	a0,s8,80003e56 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003df6:	8526                	mv	a0,s1
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	788080e7          	jalr	1928(ra) # 80004580 <log_write>
    brelse(bp);
    80003e00:	8526                	mv	a0,s1
    80003e02:	fffff097          	auipc	ra,0xfffff
    80003e06:	4f4080e7          	jalr	1268(ra) # 800032f6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e0a:	013d09bb          	addw	s3,s10,s3
    80003e0e:	012d093b          	addw	s2,s10,s2
    80003e12:	9a6e                	add	s4,s4,s11
    80003e14:	0569f663          	bgeu	s3,s6,80003e60 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e18:	00a9559b          	srliw	a1,s2,0xa
    80003e1c:	8556                	mv	a0,s5
    80003e1e:	fffff097          	auipc	ra,0xfffff
    80003e22:	79c080e7          	jalr	1948(ra) # 800035ba <bmap>
    80003e26:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e2a:	c99d                	beqz	a1,80003e60 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e2c:	000aa503          	lw	a0,0(s5)
    80003e30:	fffff097          	auipc	ra,0xfffff
    80003e34:	396080e7          	jalr	918(ra) # 800031c6 <bread>
    80003e38:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e3a:	3ff97713          	andi	a4,s2,1023
    80003e3e:	40ec87bb          	subw	a5,s9,a4
    80003e42:	413b06bb          	subw	a3,s6,s3
    80003e46:	8d3e                	mv	s10,a5
    80003e48:	2781                	sext.w	a5,a5
    80003e4a:	0006861b          	sext.w	a2,a3
    80003e4e:	f8f674e3          	bgeu	a2,a5,80003dd6 <writei+0x4c>
    80003e52:	8d36                	mv	s10,a3
    80003e54:	b749                	j	80003dd6 <writei+0x4c>
      brelse(bp);
    80003e56:	8526                	mv	a0,s1
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	49e080e7          	jalr	1182(ra) # 800032f6 <brelse>
  }

  if(off > ip->size)
    80003e60:	04caa783          	lw	a5,76(s5)
    80003e64:	0127f463          	bgeu	a5,s2,80003e6c <writei+0xe2>
    ip->size = off;
    80003e68:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e6c:	8556                	mv	a0,s5
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	aa4080e7          	jalr	-1372(ra) # 80003912 <iupdate>

  return tot;
    80003e76:	0009851b          	sext.w	a0,s3
}
    80003e7a:	70a6                	ld	ra,104(sp)
    80003e7c:	7406                	ld	s0,96(sp)
    80003e7e:	64e6                	ld	s1,88(sp)
    80003e80:	6946                	ld	s2,80(sp)
    80003e82:	69a6                	ld	s3,72(sp)
    80003e84:	6a06                	ld	s4,64(sp)
    80003e86:	7ae2                	ld	s5,56(sp)
    80003e88:	7b42                	ld	s6,48(sp)
    80003e8a:	7ba2                	ld	s7,40(sp)
    80003e8c:	7c02                	ld	s8,32(sp)
    80003e8e:	6ce2                	ld	s9,24(sp)
    80003e90:	6d42                	ld	s10,16(sp)
    80003e92:	6da2                	ld	s11,8(sp)
    80003e94:	6165                	addi	sp,sp,112
    80003e96:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e98:	89da                	mv	s3,s6
    80003e9a:	bfc9                	j	80003e6c <writei+0xe2>
    return -1;
    80003e9c:	557d                	li	a0,-1
}
    80003e9e:	8082                	ret
    return -1;
    80003ea0:	557d                	li	a0,-1
    80003ea2:	bfe1                	j	80003e7a <writei+0xf0>
    return -1;
    80003ea4:	557d                	li	a0,-1
    80003ea6:	bfd1                	j	80003e7a <writei+0xf0>

0000000080003ea8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ea8:	1141                	addi	sp,sp,-16
    80003eaa:	e406                	sd	ra,8(sp)
    80003eac:	e022                	sd	s0,0(sp)
    80003eae:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003eb0:	4639                	li	a2,14
    80003eb2:	ffffd097          	auipc	ra,0xffffd
    80003eb6:	ef0080e7          	jalr	-272(ra) # 80000da2 <strncmp>
}
    80003eba:	60a2                	ld	ra,8(sp)
    80003ebc:	6402                	ld	s0,0(sp)
    80003ebe:	0141                	addi	sp,sp,16
    80003ec0:	8082                	ret

0000000080003ec2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ec2:	7139                	addi	sp,sp,-64
    80003ec4:	fc06                	sd	ra,56(sp)
    80003ec6:	f822                	sd	s0,48(sp)
    80003ec8:	f426                	sd	s1,40(sp)
    80003eca:	f04a                	sd	s2,32(sp)
    80003ecc:	ec4e                	sd	s3,24(sp)
    80003ece:	e852                	sd	s4,16(sp)
    80003ed0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ed2:	04451703          	lh	a4,68(a0)
    80003ed6:	4785                	li	a5,1
    80003ed8:	00f71a63          	bne	a4,a5,80003eec <dirlookup+0x2a>
    80003edc:	892a                	mv	s2,a0
    80003ede:	89ae                	mv	s3,a1
    80003ee0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee2:	457c                	lw	a5,76(a0)
    80003ee4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ee6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee8:	e79d                	bnez	a5,80003f16 <dirlookup+0x54>
    80003eea:	a8a5                	j	80003f62 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003eec:	00004517          	auipc	a0,0x4
    80003ef0:	72450513          	addi	a0,a0,1828 # 80008610 <syscalls+0x1c0>
    80003ef4:	ffffc097          	auipc	ra,0xffffc
    80003ef8:	64c080e7          	jalr	1612(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003efc:	00004517          	auipc	a0,0x4
    80003f00:	72c50513          	addi	a0,a0,1836 # 80008628 <syscalls+0x1d8>
    80003f04:	ffffc097          	auipc	ra,0xffffc
    80003f08:	63c080e7          	jalr	1596(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0c:	24c1                	addiw	s1,s1,16
    80003f0e:	04c92783          	lw	a5,76(s2)
    80003f12:	04f4f763          	bgeu	s1,a5,80003f60 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f16:	4741                	li	a4,16
    80003f18:	86a6                	mv	a3,s1
    80003f1a:	fc040613          	addi	a2,s0,-64
    80003f1e:	4581                	li	a1,0
    80003f20:	854a                	mv	a0,s2
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	d70080e7          	jalr	-656(ra) # 80003c92 <readi>
    80003f2a:	47c1                	li	a5,16
    80003f2c:	fcf518e3          	bne	a0,a5,80003efc <dirlookup+0x3a>
    if(de.inum == 0)
    80003f30:	fc045783          	lhu	a5,-64(s0)
    80003f34:	dfe1                	beqz	a5,80003f0c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f36:	fc240593          	addi	a1,s0,-62
    80003f3a:	854e                	mv	a0,s3
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	f6c080e7          	jalr	-148(ra) # 80003ea8 <namecmp>
    80003f44:	f561                	bnez	a0,80003f0c <dirlookup+0x4a>
      if(poff)
    80003f46:	000a0463          	beqz	s4,80003f4e <dirlookup+0x8c>
        *poff = off;
    80003f4a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f4e:	fc045583          	lhu	a1,-64(s0)
    80003f52:	00092503          	lw	a0,0(s2)
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	74e080e7          	jalr	1870(ra) # 800036a4 <iget>
    80003f5e:	a011                	j	80003f62 <dirlookup+0xa0>
  return 0;
    80003f60:	4501                	li	a0,0
}
    80003f62:	70e2                	ld	ra,56(sp)
    80003f64:	7442                	ld	s0,48(sp)
    80003f66:	74a2                	ld	s1,40(sp)
    80003f68:	7902                	ld	s2,32(sp)
    80003f6a:	69e2                	ld	s3,24(sp)
    80003f6c:	6a42                	ld	s4,16(sp)
    80003f6e:	6121                	addi	sp,sp,64
    80003f70:	8082                	ret

0000000080003f72 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f72:	711d                	addi	sp,sp,-96
    80003f74:	ec86                	sd	ra,88(sp)
    80003f76:	e8a2                	sd	s0,80(sp)
    80003f78:	e4a6                	sd	s1,72(sp)
    80003f7a:	e0ca                	sd	s2,64(sp)
    80003f7c:	fc4e                	sd	s3,56(sp)
    80003f7e:	f852                	sd	s4,48(sp)
    80003f80:	f456                	sd	s5,40(sp)
    80003f82:	f05a                	sd	s6,32(sp)
    80003f84:	ec5e                	sd	s7,24(sp)
    80003f86:	e862                	sd	s8,16(sp)
    80003f88:	e466                	sd	s9,8(sp)
    80003f8a:	e06a                	sd	s10,0(sp)
    80003f8c:	1080                	addi	s0,sp,96
    80003f8e:	84aa                	mv	s1,a0
    80003f90:	8b2e                	mv	s6,a1
    80003f92:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f94:	00054703          	lbu	a4,0(a0)
    80003f98:	02f00793          	li	a5,47
    80003f9c:	02f70363          	beq	a4,a5,80003fc2 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fa0:	ffffe097          	auipc	ra,0xffffe
    80003fa4:	a0c080e7          	jalr	-1524(ra) # 800019ac <myproc>
    80003fa8:	15053503          	ld	a0,336(a0)
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	9f4080e7          	jalr	-1548(ra) # 800039a0 <idup>
    80003fb4:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003fb6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003fba:	4cb5                	li	s9,13
  len = path - s;
    80003fbc:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fbe:	4c05                	li	s8,1
    80003fc0:	a87d                	j	8000407e <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003fc2:	4585                	li	a1,1
    80003fc4:	4505                	li	a0,1
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	6de080e7          	jalr	1758(ra) # 800036a4 <iget>
    80003fce:	8a2a                	mv	s4,a0
    80003fd0:	b7dd                	j	80003fb6 <namex+0x44>
      iunlockput(ip);
    80003fd2:	8552                	mv	a0,s4
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	c6c080e7          	jalr	-916(ra) # 80003c40 <iunlockput>
      return 0;
    80003fdc:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fde:	8552                	mv	a0,s4
    80003fe0:	60e6                	ld	ra,88(sp)
    80003fe2:	6446                	ld	s0,80(sp)
    80003fe4:	64a6                	ld	s1,72(sp)
    80003fe6:	6906                	ld	s2,64(sp)
    80003fe8:	79e2                	ld	s3,56(sp)
    80003fea:	7a42                	ld	s4,48(sp)
    80003fec:	7aa2                	ld	s5,40(sp)
    80003fee:	7b02                	ld	s6,32(sp)
    80003ff0:	6be2                	ld	s7,24(sp)
    80003ff2:	6c42                	ld	s8,16(sp)
    80003ff4:	6ca2                	ld	s9,8(sp)
    80003ff6:	6d02                	ld	s10,0(sp)
    80003ff8:	6125                	addi	sp,sp,96
    80003ffa:	8082                	ret
      iunlock(ip);
    80003ffc:	8552                	mv	a0,s4
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	aa2080e7          	jalr	-1374(ra) # 80003aa0 <iunlock>
      return ip;
    80004006:	bfe1                	j	80003fde <namex+0x6c>
      iunlockput(ip);
    80004008:	8552                	mv	a0,s4
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	c36080e7          	jalr	-970(ra) # 80003c40 <iunlockput>
      return 0;
    80004012:	8a4e                	mv	s4,s3
    80004014:	b7e9                	j	80003fde <namex+0x6c>
  len = path - s;
    80004016:	40998633          	sub	a2,s3,s1
    8000401a:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000401e:	09acd863          	bge	s9,s10,800040ae <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004022:	4639                	li	a2,14
    80004024:	85a6                	mv	a1,s1
    80004026:	8556                	mv	a0,s5
    80004028:	ffffd097          	auipc	ra,0xffffd
    8000402c:	d06080e7          	jalr	-762(ra) # 80000d2e <memmove>
    80004030:	84ce                	mv	s1,s3
  while(*path == '/')
    80004032:	0004c783          	lbu	a5,0(s1)
    80004036:	01279763          	bne	a5,s2,80004044 <namex+0xd2>
    path++;
    8000403a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000403c:	0004c783          	lbu	a5,0(s1)
    80004040:	ff278de3          	beq	a5,s2,8000403a <namex+0xc8>
    ilock(ip);
    80004044:	8552                	mv	a0,s4
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	998080e7          	jalr	-1640(ra) # 800039de <ilock>
    if(ip->type != T_DIR){
    8000404e:	044a1783          	lh	a5,68(s4)
    80004052:	f98790e3          	bne	a5,s8,80003fd2 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004056:	000b0563          	beqz	s6,80004060 <namex+0xee>
    8000405a:	0004c783          	lbu	a5,0(s1)
    8000405e:	dfd9                	beqz	a5,80003ffc <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004060:	865e                	mv	a2,s7
    80004062:	85d6                	mv	a1,s5
    80004064:	8552                	mv	a0,s4
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	e5c080e7          	jalr	-420(ra) # 80003ec2 <dirlookup>
    8000406e:	89aa                	mv	s3,a0
    80004070:	dd41                	beqz	a0,80004008 <namex+0x96>
    iunlockput(ip);
    80004072:	8552                	mv	a0,s4
    80004074:	00000097          	auipc	ra,0x0
    80004078:	bcc080e7          	jalr	-1076(ra) # 80003c40 <iunlockput>
    ip = next;
    8000407c:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000407e:	0004c783          	lbu	a5,0(s1)
    80004082:	01279763          	bne	a5,s2,80004090 <namex+0x11e>
    path++;
    80004086:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004088:	0004c783          	lbu	a5,0(s1)
    8000408c:	ff278de3          	beq	a5,s2,80004086 <namex+0x114>
  if(*path == 0)
    80004090:	cb9d                	beqz	a5,800040c6 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004092:	0004c783          	lbu	a5,0(s1)
    80004096:	89a6                	mv	s3,s1
  len = path - s;
    80004098:	8d5e                	mv	s10,s7
    8000409a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000409c:	01278963          	beq	a5,s2,800040ae <namex+0x13c>
    800040a0:	dbbd                	beqz	a5,80004016 <namex+0xa4>
    path++;
    800040a2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800040a4:	0009c783          	lbu	a5,0(s3)
    800040a8:	ff279ce3          	bne	a5,s2,800040a0 <namex+0x12e>
    800040ac:	b7ad                	j	80004016 <namex+0xa4>
    memmove(name, s, len);
    800040ae:	2601                	sext.w	a2,a2
    800040b0:	85a6                	mv	a1,s1
    800040b2:	8556                	mv	a0,s5
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	c7a080e7          	jalr	-902(ra) # 80000d2e <memmove>
    name[len] = 0;
    800040bc:	9d56                	add	s10,s10,s5
    800040be:	000d0023          	sb	zero,0(s10)
    800040c2:	84ce                	mv	s1,s3
    800040c4:	b7bd                	j	80004032 <namex+0xc0>
  if(nameiparent){
    800040c6:	f00b0ce3          	beqz	s6,80003fde <namex+0x6c>
    iput(ip);
    800040ca:	8552                	mv	a0,s4
    800040cc:	00000097          	auipc	ra,0x0
    800040d0:	acc080e7          	jalr	-1332(ra) # 80003b98 <iput>
    return 0;
    800040d4:	4a01                	li	s4,0
    800040d6:	b721                	j	80003fde <namex+0x6c>

00000000800040d8 <dirlink>:
{
    800040d8:	7139                	addi	sp,sp,-64
    800040da:	fc06                	sd	ra,56(sp)
    800040dc:	f822                	sd	s0,48(sp)
    800040de:	f426                	sd	s1,40(sp)
    800040e0:	f04a                	sd	s2,32(sp)
    800040e2:	ec4e                	sd	s3,24(sp)
    800040e4:	e852                	sd	s4,16(sp)
    800040e6:	0080                	addi	s0,sp,64
    800040e8:	892a                	mv	s2,a0
    800040ea:	8a2e                	mv	s4,a1
    800040ec:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040ee:	4601                	li	a2,0
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	dd2080e7          	jalr	-558(ra) # 80003ec2 <dirlookup>
    800040f8:	e93d                	bnez	a0,8000416e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040fa:	04c92483          	lw	s1,76(s2)
    800040fe:	c49d                	beqz	s1,8000412c <dirlink+0x54>
    80004100:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004102:	4741                	li	a4,16
    80004104:	86a6                	mv	a3,s1
    80004106:	fc040613          	addi	a2,s0,-64
    8000410a:	4581                	li	a1,0
    8000410c:	854a                	mv	a0,s2
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	b84080e7          	jalr	-1148(ra) # 80003c92 <readi>
    80004116:	47c1                	li	a5,16
    80004118:	06f51163          	bne	a0,a5,8000417a <dirlink+0xa2>
    if(de.inum == 0)
    8000411c:	fc045783          	lhu	a5,-64(s0)
    80004120:	c791                	beqz	a5,8000412c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004122:	24c1                	addiw	s1,s1,16
    80004124:	04c92783          	lw	a5,76(s2)
    80004128:	fcf4ede3          	bltu	s1,a5,80004102 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000412c:	4639                	li	a2,14
    8000412e:	85d2                	mv	a1,s4
    80004130:	fc240513          	addi	a0,s0,-62
    80004134:	ffffd097          	auipc	ra,0xffffd
    80004138:	caa080e7          	jalr	-854(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000413c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004140:	4741                	li	a4,16
    80004142:	86a6                	mv	a3,s1
    80004144:	fc040613          	addi	a2,s0,-64
    80004148:	4581                	li	a1,0
    8000414a:	854a                	mv	a0,s2
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	c3e080e7          	jalr	-962(ra) # 80003d8a <writei>
    80004154:	1541                	addi	a0,a0,-16
    80004156:	00a03533          	snez	a0,a0
    8000415a:	40a00533          	neg	a0,a0
}
    8000415e:	70e2                	ld	ra,56(sp)
    80004160:	7442                	ld	s0,48(sp)
    80004162:	74a2                	ld	s1,40(sp)
    80004164:	7902                	ld	s2,32(sp)
    80004166:	69e2                	ld	s3,24(sp)
    80004168:	6a42                	ld	s4,16(sp)
    8000416a:	6121                	addi	sp,sp,64
    8000416c:	8082                	ret
    iput(ip);
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	a2a080e7          	jalr	-1494(ra) # 80003b98 <iput>
    return -1;
    80004176:	557d                	li	a0,-1
    80004178:	b7dd                	j	8000415e <dirlink+0x86>
      panic("dirlink read");
    8000417a:	00004517          	auipc	a0,0x4
    8000417e:	4be50513          	addi	a0,a0,1214 # 80008638 <syscalls+0x1e8>
    80004182:	ffffc097          	auipc	ra,0xffffc
    80004186:	3be080e7          	jalr	958(ra) # 80000540 <panic>

000000008000418a <namei>:

struct inode*
namei(char *path)
{
    8000418a:	1101                	addi	sp,sp,-32
    8000418c:	ec06                	sd	ra,24(sp)
    8000418e:	e822                	sd	s0,16(sp)
    80004190:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004192:	fe040613          	addi	a2,s0,-32
    80004196:	4581                	li	a1,0
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	dda080e7          	jalr	-550(ra) # 80003f72 <namex>
}
    800041a0:	60e2                	ld	ra,24(sp)
    800041a2:	6442                	ld	s0,16(sp)
    800041a4:	6105                	addi	sp,sp,32
    800041a6:	8082                	ret

00000000800041a8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041a8:	1141                	addi	sp,sp,-16
    800041aa:	e406                	sd	ra,8(sp)
    800041ac:	e022                	sd	s0,0(sp)
    800041ae:	0800                	addi	s0,sp,16
    800041b0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041b2:	4585                	li	a1,1
    800041b4:	00000097          	auipc	ra,0x0
    800041b8:	dbe080e7          	jalr	-578(ra) # 80003f72 <namex>
}
    800041bc:	60a2                	ld	ra,8(sp)
    800041be:	6402                	ld	s0,0(sp)
    800041c0:	0141                	addi	sp,sp,16
    800041c2:	8082                	ret

00000000800041c4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041c4:	1101                	addi	sp,sp,-32
    800041c6:	ec06                	sd	ra,24(sp)
    800041c8:	e822                	sd	s0,16(sp)
    800041ca:	e426                	sd	s1,8(sp)
    800041cc:	e04a                	sd	s2,0(sp)
    800041ce:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041d0:	0001d917          	auipc	s2,0x1d
    800041d4:	78090913          	addi	s2,s2,1920 # 80021950 <log>
    800041d8:	01892583          	lw	a1,24(s2)
    800041dc:	02892503          	lw	a0,40(s2)
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	fe6080e7          	jalr	-26(ra) # 800031c6 <bread>
    800041e8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041ea:	02c92683          	lw	a3,44(s2)
    800041ee:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041f0:	02d05863          	blez	a3,80004220 <write_head+0x5c>
    800041f4:	0001d797          	auipc	a5,0x1d
    800041f8:	78c78793          	addi	a5,a5,1932 # 80021980 <log+0x30>
    800041fc:	05c50713          	addi	a4,a0,92
    80004200:	36fd                	addiw	a3,a3,-1
    80004202:	02069613          	slli	a2,a3,0x20
    80004206:	01e65693          	srli	a3,a2,0x1e
    8000420a:	0001d617          	auipc	a2,0x1d
    8000420e:	77a60613          	addi	a2,a2,1914 # 80021984 <log+0x34>
    80004212:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004214:	4390                	lw	a2,0(a5)
    80004216:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004218:	0791                	addi	a5,a5,4
    8000421a:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000421c:	fed79ce3          	bne	a5,a3,80004214 <write_head+0x50>
  }
  bwrite(buf);
    80004220:	8526                	mv	a0,s1
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	096080e7          	jalr	150(ra) # 800032b8 <bwrite>
  brelse(buf);
    8000422a:	8526                	mv	a0,s1
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	0ca080e7          	jalr	202(ra) # 800032f6 <brelse>
}
    80004234:	60e2                	ld	ra,24(sp)
    80004236:	6442                	ld	s0,16(sp)
    80004238:	64a2                	ld	s1,8(sp)
    8000423a:	6902                	ld	s2,0(sp)
    8000423c:	6105                	addi	sp,sp,32
    8000423e:	8082                	ret

0000000080004240 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004240:	0001d797          	auipc	a5,0x1d
    80004244:	73c7a783          	lw	a5,1852(a5) # 8002197c <log+0x2c>
    80004248:	0af05d63          	blez	a5,80004302 <install_trans+0xc2>
{
    8000424c:	7139                	addi	sp,sp,-64
    8000424e:	fc06                	sd	ra,56(sp)
    80004250:	f822                	sd	s0,48(sp)
    80004252:	f426                	sd	s1,40(sp)
    80004254:	f04a                	sd	s2,32(sp)
    80004256:	ec4e                	sd	s3,24(sp)
    80004258:	e852                	sd	s4,16(sp)
    8000425a:	e456                	sd	s5,8(sp)
    8000425c:	e05a                	sd	s6,0(sp)
    8000425e:	0080                	addi	s0,sp,64
    80004260:	8b2a                	mv	s6,a0
    80004262:	0001da97          	auipc	s5,0x1d
    80004266:	71ea8a93          	addi	s5,s5,1822 # 80021980 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000426c:	0001d997          	auipc	s3,0x1d
    80004270:	6e498993          	addi	s3,s3,1764 # 80021950 <log>
    80004274:	a00d                	j	80004296 <install_trans+0x56>
    brelse(lbuf);
    80004276:	854a                	mv	a0,s2
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	07e080e7          	jalr	126(ra) # 800032f6 <brelse>
    brelse(dbuf);
    80004280:	8526                	mv	a0,s1
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	074080e7          	jalr	116(ra) # 800032f6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428a:	2a05                	addiw	s4,s4,1
    8000428c:	0a91                	addi	s5,s5,4
    8000428e:	02c9a783          	lw	a5,44(s3)
    80004292:	04fa5e63          	bge	s4,a5,800042ee <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004296:	0189a583          	lw	a1,24(s3)
    8000429a:	014585bb          	addw	a1,a1,s4
    8000429e:	2585                	addiw	a1,a1,1
    800042a0:	0289a503          	lw	a0,40(s3)
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	f22080e7          	jalr	-222(ra) # 800031c6 <bread>
    800042ac:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042ae:	000aa583          	lw	a1,0(s5)
    800042b2:	0289a503          	lw	a0,40(s3)
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	f10080e7          	jalr	-240(ra) # 800031c6 <bread>
    800042be:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042c0:	40000613          	li	a2,1024
    800042c4:	05890593          	addi	a1,s2,88
    800042c8:	05850513          	addi	a0,a0,88
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	a62080e7          	jalr	-1438(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800042d4:	8526                	mv	a0,s1
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	fe2080e7          	jalr	-30(ra) # 800032b8 <bwrite>
    if(recovering == 0)
    800042de:	f80b1ce3          	bnez	s6,80004276 <install_trans+0x36>
      bunpin(dbuf);
    800042e2:	8526                	mv	a0,s1
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	0ec080e7          	jalr	236(ra) # 800033d0 <bunpin>
    800042ec:	b769                	j	80004276 <install_trans+0x36>
}
    800042ee:	70e2                	ld	ra,56(sp)
    800042f0:	7442                	ld	s0,48(sp)
    800042f2:	74a2                	ld	s1,40(sp)
    800042f4:	7902                	ld	s2,32(sp)
    800042f6:	69e2                	ld	s3,24(sp)
    800042f8:	6a42                	ld	s4,16(sp)
    800042fa:	6aa2                	ld	s5,8(sp)
    800042fc:	6b02                	ld	s6,0(sp)
    800042fe:	6121                	addi	sp,sp,64
    80004300:	8082                	ret
    80004302:	8082                	ret

0000000080004304 <initlog>:
{
    80004304:	7179                	addi	sp,sp,-48
    80004306:	f406                	sd	ra,40(sp)
    80004308:	f022                	sd	s0,32(sp)
    8000430a:	ec26                	sd	s1,24(sp)
    8000430c:	e84a                	sd	s2,16(sp)
    8000430e:	e44e                	sd	s3,8(sp)
    80004310:	1800                	addi	s0,sp,48
    80004312:	892a                	mv	s2,a0
    80004314:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004316:	0001d497          	auipc	s1,0x1d
    8000431a:	63a48493          	addi	s1,s1,1594 # 80021950 <log>
    8000431e:	00004597          	auipc	a1,0x4
    80004322:	32a58593          	addi	a1,a1,810 # 80008648 <syscalls+0x1f8>
    80004326:	8526                	mv	a0,s1
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	81e080e7          	jalr	-2018(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004330:	0149a583          	lw	a1,20(s3)
    80004334:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004336:	0109a783          	lw	a5,16(s3)
    8000433a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000433c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004340:	854a                	mv	a0,s2
    80004342:	fffff097          	auipc	ra,0xfffff
    80004346:	e84080e7          	jalr	-380(ra) # 800031c6 <bread>
  log.lh.n = lh->n;
    8000434a:	4d34                	lw	a3,88(a0)
    8000434c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000434e:	02d05663          	blez	a3,8000437a <initlog+0x76>
    80004352:	05c50793          	addi	a5,a0,92
    80004356:	0001d717          	auipc	a4,0x1d
    8000435a:	62a70713          	addi	a4,a4,1578 # 80021980 <log+0x30>
    8000435e:	36fd                	addiw	a3,a3,-1
    80004360:	02069613          	slli	a2,a3,0x20
    80004364:	01e65693          	srli	a3,a2,0x1e
    80004368:	06050613          	addi	a2,a0,96
    8000436c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000436e:	4390                	lw	a2,0(a5)
    80004370:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004372:	0791                	addi	a5,a5,4
    80004374:	0711                	addi	a4,a4,4
    80004376:	fed79ce3          	bne	a5,a3,8000436e <initlog+0x6a>
  brelse(buf);
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	f7c080e7          	jalr	-132(ra) # 800032f6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004382:	4505                	li	a0,1
    80004384:	00000097          	auipc	ra,0x0
    80004388:	ebc080e7          	jalr	-324(ra) # 80004240 <install_trans>
  log.lh.n = 0;
    8000438c:	0001d797          	auipc	a5,0x1d
    80004390:	5e07a823          	sw	zero,1520(a5) # 8002197c <log+0x2c>
  write_head(); // clear the log
    80004394:	00000097          	auipc	ra,0x0
    80004398:	e30080e7          	jalr	-464(ra) # 800041c4 <write_head>
}
    8000439c:	70a2                	ld	ra,40(sp)
    8000439e:	7402                	ld	s0,32(sp)
    800043a0:	64e2                	ld	s1,24(sp)
    800043a2:	6942                	ld	s2,16(sp)
    800043a4:	69a2                	ld	s3,8(sp)
    800043a6:	6145                	addi	sp,sp,48
    800043a8:	8082                	ret

00000000800043aa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043aa:	1101                	addi	sp,sp,-32
    800043ac:	ec06                	sd	ra,24(sp)
    800043ae:	e822                	sd	s0,16(sp)
    800043b0:	e426                	sd	s1,8(sp)
    800043b2:	e04a                	sd	s2,0(sp)
    800043b4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043b6:	0001d517          	auipc	a0,0x1d
    800043ba:	59a50513          	addi	a0,a0,1434 # 80021950 <log>
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	818080e7          	jalr	-2024(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800043c6:	0001d497          	auipc	s1,0x1d
    800043ca:	58a48493          	addi	s1,s1,1418 # 80021950 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043ce:	4979                	li	s2,30
    800043d0:	a039                	j	800043de <begin_op+0x34>
      sleep(&log, &log.lock);
    800043d2:	85a6                	mv	a1,s1
    800043d4:	8526                	mv	a0,s1
    800043d6:	ffffe097          	auipc	ra,0xffffe
    800043da:	ca2080e7          	jalr	-862(ra) # 80002078 <sleep>
    if(log.committing){
    800043de:	50dc                	lw	a5,36(s1)
    800043e0:	fbed                	bnez	a5,800043d2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043e2:	5098                	lw	a4,32(s1)
    800043e4:	2705                	addiw	a4,a4,1
    800043e6:	0007069b          	sext.w	a3,a4
    800043ea:	0027179b          	slliw	a5,a4,0x2
    800043ee:	9fb9                	addw	a5,a5,a4
    800043f0:	0017979b          	slliw	a5,a5,0x1
    800043f4:	54d8                	lw	a4,44(s1)
    800043f6:	9fb9                	addw	a5,a5,a4
    800043f8:	00f95963          	bge	s2,a5,8000440a <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043fc:	85a6                	mv	a1,s1
    800043fe:	8526                	mv	a0,s1
    80004400:	ffffe097          	auipc	ra,0xffffe
    80004404:	c78080e7          	jalr	-904(ra) # 80002078 <sleep>
    80004408:	bfd9                	j	800043de <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000440a:	0001d517          	auipc	a0,0x1d
    8000440e:	54650513          	addi	a0,a0,1350 # 80021950 <log>
    80004412:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	876080e7          	jalr	-1930(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000441c:	60e2                	ld	ra,24(sp)
    8000441e:	6442                	ld	s0,16(sp)
    80004420:	64a2                	ld	s1,8(sp)
    80004422:	6902                	ld	s2,0(sp)
    80004424:	6105                	addi	sp,sp,32
    80004426:	8082                	ret

0000000080004428 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004428:	7139                	addi	sp,sp,-64
    8000442a:	fc06                	sd	ra,56(sp)
    8000442c:	f822                	sd	s0,48(sp)
    8000442e:	f426                	sd	s1,40(sp)
    80004430:	f04a                	sd	s2,32(sp)
    80004432:	ec4e                	sd	s3,24(sp)
    80004434:	e852                	sd	s4,16(sp)
    80004436:	e456                	sd	s5,8(sp)
    80004438:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000443a:	0001d497          	auipc	s1,0x1d
    8000443e:	51648493          	addi	s1,s1,1302 # 80021950 <log>
    80004442:	8526                	mv	a0,s1
    80004444:	ffffc097          	auipc	ra,0xffffc
    80004448:	792080e7          	jalr	1938(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000444c:	509c                	lw	a5,32(s1)
    8000444e:	37fd                	addiw	a5,a5,-1
    80004450:	0007891b          	sext.w	s2,a5
    80004454:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004456:	50dc                	lw	a5,36(s1)
    80004458:	e7b9                	bnez	a5,800044a6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000445a:	04091e63          	bnez	s2,800044b6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000445e:	0001d497          	auipc	s1,0x1d
    80004462:	4f248493          	addi	s1,s1,1266 # 80021950 <log>
    80004466:	4785                	li	a5,1
    80004468:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffd097          	auipc	ra,0xffffd
    80004470:	81e080e7          	jalr	-2018(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004474:	54dc                	lw	a5,44(s1)
    80004476:	06f04763          	bgtz	a5,800044e4 <end_op+0xbc>
    acquire(&log.lock);
    8000447a:	0001d497          	auipc	s1,0x1d
    8000447e:	4d648493          	addi	s1,s1,1238 # 80021950 <log>
    80004482:	8526                	mv	a0,s1
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	752080e7          	jalr	1874(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000448c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004490:	8526                	mv	a0,s1
    80004492:	ffffe097          	auipc	ra,0xffffe
    80004496:	c4a080e7          	jalr	-950(ra) # 800020dc <wakeup>
    release(&log.lock);
    8000449a:	8526                	mv	a0,s1
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	7ee080e7          	jalr	2030(ra) # 80000c8a <release>
}
    800044a4:	a03d                	j	800044d2 <end_op+0xaa>
    panic("log.committing");
    800044a6:	00004517          	auipc	a0,0x4
    800044aa:	1aa50513          	addi	a0,a0,426 # 80008650 <syscalls+0x200>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	092080e7          	jalr	146(ra) # 80000540 <panic>
    wakeup(&log);
    800044b6:	0001d497          	auipc	s1,0x1d
    800044ba:	49a48493          	addi	s1,s1,1178 # 80021950 <log>
    800044be:	8526                	mv	a0,s1
    800044c0:	ffffe097          	auipc	ra,0xffffe
    800044c4:	c1c080e7          	jalr	-996(ra) # 800020dc <wakeup>
  release(&log.lock);
    800044c8:	8526                	mv	a0,s1
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	7c0080e7          	jalr	1984(ra) # 80000c8a <release>
}
    800044d2:	70e2                	ld	ra,56(sp)
    800044d4:	7442                	ld	s0,48(sp)
    800044d6:	74a2                	ld	s1,40(sp)
    800044d8:	7902                	ld	s2,32(sp)
    800044da:	69e2                	ld	s3,24(sp)
    800044dc:	6a42                	ld	s4,16(sp)
    800044de:	6aa2                	ld	s5,8(sp)
    800044e0:	6121                	addi	sp,sp,64
    800044e2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e4:	0001da97          	auipc	s5,0x1d
    800044e8:	49ca8a93          	addi	s5,s5,1180 # 80021980 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044ec:	0001da17          	auipc	s4,0x1d
    800044f0:	464a0a13          	addi	s4,s4,1124 # 80021950 <log>
    800044f4:	018a2583          	lw	a1,24(s4)
    800044f8:	012585bb          	addw	a1,a1,s2
    800044fc:	2585                	addiw	a1,a1,1
    800044fe:	028a2503          	lw	a0,40(s4)
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	cc4080e7          	jalr	-828(ra) # 800031c6 <bread>
    8000450a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000450c:	000aa583          	lw	a1,0(s5)
    80004510:	028a2503          	lw	a0,40(s4)
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	cb2080e7          	jalr	-846(ra) # 800031c6 <bread>
    8000451c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000451e:	40000613          	li	a2,1024
    80004522:	05850593          	addi	a1,a0,88
    80004526:	05848513          	addi	a0,s1,88
    8000452a:	ffffd097          	auipc	ra,0xffffd
    8000452e:	804080e7          	jalr	-2044(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004532:	8526                	mv	a0,s1
    80004534:	fffff097          	auipc	ra,0xfffff
    80004538:	d84080e7          	jalr	-636(ra) # 800032b8 <bwrite>
    brelse(from);
    8000453c:	854e                	mv	a0,s3
    8000453e:	fffff097          	auipc	ra,0xfffff
    80004542:	db8080e7          	jalr	-584(ra) # 800032f6 <brelse>
    brelse(to);
    80004546:	8526                	mv	a0,s1
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	dae080e7          	jalr	-594(ra) # 800032f6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004550:	2905                	addiw	s2,s2,1
    80004552:	0a91                	addi	s5,s5,4
    80004554:	02ca2783          	lw	a5,44(s4)
    80004558:	f8f94ee3          	blt	s2,a5,800044f4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	c68080e7          	jalr	-920(ra) # 800041c4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004564:	4501                	li	a0,0
    80004566:	00000097          	auipc	ra,0x0
    8000456a:	cda080e7          	jalr	-806(ra) # 80004240 <install_trans>
    log.lh.n = 0;
    8000456e:	0001d797          	auipc	a5,0x1d
    80004572:	4007a723          	sw	zero,1038(a5) # 8002197c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004576:	00000097          	auipc	ra,0x0
    8000457a:	c4e080e7          	jalr	-946(ra) # 800041c4 <write_head>
    8000457e:	bdf5                	j	8000447a <end_op+0x52>

0000000080004580 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004580:	1101                	addi	sp,sp,-32
    80004582:	ec06                	sd	ra,24(sp)
    80004584:	e822                	sd	s0,16(sp)
    80004586:	e426                	sd	s1,8(sp)
    80004588:	e04a                	sd	s2,0(sp)
    8000458a:	1000                	addi	s0,sp,32
    8000458c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000458e:	0001d917          	auipc	s2,0x1d
    80004592:	3c290913          	addi	s2,s2,962 # 80021950 <log>
    80004596:	854a                	mv	a0,s2
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	63e080e7          	jalr	1598(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045a0:	02c92603          	lw	a2,44(s2)
    800045a4:	47f5                	li	a5,29
    800045a6:	06c7c563          	blt	a5,a2,80004610 <log_write+0x90>
    800045aa:	0001d797          	auipc	a5,0x1d
    800045ae:	3c27a783          	lw	a5,962(a5) # 8002196c <log+0x1c>
    800045b2:	37fd                	addiw	a5,a5,-1
    800045b4:	04f65e63          	bge	a2,a5,80004610 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045b8:	0001d797          	auipc	a5,0x1d
    800045bc:	3b87a783          	lw	a5,952(a5) # 80021970 <log+0x20>
    800045c0:	06f05063          	blez	a5,80004620 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045c4:	4781                	li	a5,0
    800045c6:	06c05563          	blez	a2,80004630 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045ca:	44cc                	lw	a1,12(s1)
    800045cc:	0001d717          	auipc	a4,0x1d
    800045d0:	3b470713          	addi	a4,a4,948 # 80021980 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045d4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045d6:	4314                	lw	a3,0(a4)
    800045d8:	04b68c63          	beq	a3,a1,80004630 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045dc:	2785                	addiw	a5,a5,1
    800045de:	0711                	addi	a4,a4,4
    800045e0:	fef61be3          	bne	a2,a5,800045d6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045e4:	0621                	addi	a2,a2,8
    800045e6:	060a                	slli	a2,a2,0x2
    800045e8:	0001d797          	auipc	a5,0x1d
    800045ec:	36878793          	addi	a5,a5,872 # 80021950 <log>
    800045f0:	97b2                	add	a5,a5,a2
    800045f2:	44d8                	lw	a4,12(s1)
    800045f4:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045f6:	8526                	mv	a0,s1
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	d9c080e7          	jalr	-612(ra) # 80003394 <bpin>
    log.lh.n++;
    80004600:	0001d717          	auipc	a4,0x1d
    80004604:	35070713          	addi	a4,a4,848 # 80021950 <log>
    80004608:	575c                	lw	a5,44(a4)
    8000460a:	2785                	addiw	a5,a5,1
    8000460c:	d75c                	sw	a5,44(a4)
    8000460e:	a82d                	j	80004648 <log_write+0xc8>
    panic("too big a transaction");
    80004610:	00004517          	auipc	a0,0x4
    80004614:	05050513          	addi	a0,a0,80 # 80008660 <syscalls+0x210>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	f28080e7          	jalr	-216(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004620:	00004517          	auipc	a0,0x4
    80004624:	05850513          	addi	a0,a0,88 # 80008678 <syscalls+0x228>
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	f18080e7          	jalr	-232(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004630:	00878693          	addi	a3,a5,8
    80004634:	068a                	slli	a3,a3,0x2
    80004636:	0001d717          	auipc	a4,0x1d
    8000463a:	31a70713          	addi	a4,a4,794 # 80021950 <log>
    8000463e:	9736                	add	a4,a4,a3
    80004640:	44d4                	lw	a3,12(s1)
    80004642:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004644:	faf609e3          	beq	a2,a5,800045f6 <log_write+0x76>
  }
  release(&log.lock);
    80004648:	0001d517          	auipc	a0,0x1d
    8000464c:	30850513          	addi	a0,a0,776 # 80021950 <log>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	63a080e7          	jalr	1594(ra) # 80000c8a <release>
}
    80004658:	60e2                	ld	ra,24(sp)
    8000465a:	6442                	ld	s0,16(sp)
    8000465c:	64a2                	ld	s1,8(sp)
    8000465e:	6902                	ld	s2,0(sp)
    80004660:	6105                	addi	sp,sp,32
    80004662:	8082                	ret

0000000080004664 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004664:	1101                	addi	sp,sp,-32
    80004666:	ec06                	sd	ra,24(sp)
    80004668:	e822                	sd	s0,16(sp)
    8000466a:	e426                	sd	s1,8(sp)
    8000466c:	e04a                	sd	s2,0(sp)
    8000466e:	1000                	addi	s0,sp,32
    80004670:	84aa                	mv	s1,a0
    80004672:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004674:	00004597          	auipc	a1,0x4
    80004678:	02458593          	addi	a1,a1,36 # 80008698 <syscalls+0x248>
    8000467c:	0521                	addi	a0,a0,8
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	4c8080e7          	jalr	1224(ra) # 80000b46 <initlock>
  lk->name = name;
    80004686:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000468a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000468e:	0204a423          	sw	zero,40(s1)
}
    80004692:	60e2                	ld	ra,24(sp)
    80004694:	6442                	ld	s0,16(sp)
    80004696:	64a2                	ld	s1,8(sp)
    80004698:	6902                	ld	s2,0(sp)
    8000469a:	6105                	addi	sp,sp,32
    8000469c:	8082                	ret

000000008000469e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000469e:	1101                	addi	sp,sp,-32
    800046a0:	ec06                	sd	ra,24(sp)
    800046a2:	e822                	sd	s0,16(sp)
    800046a4:	e426                	sd	s1,8(sp)
    800046a6:	e04a                	sd	s2,0(sp)
    800046a8:	1000                	addi	s0,sp,32
    800046aa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046ac:	00850913          	addi	s2,a0,8
    800046b0:	854a                	mv	a0,s2
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	524080e7          	jalr	1316(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800046ba:	409c                	lw	a5,0(s1)
    800046bc:	cb89                	beqz	a5,800046ce <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046be:	85ca                	mv	a1,s2
    800046c0:	8526                	mv	a0,s1
    800046c2:	ffffe097          	auipc	ra,0xffffe
    800046c6:	9b6080e7          	jalr	-1610(ra) # 80002078 <sleep>
  while (lk->locked) {
    800046ca:	409c                	lw	a5,0(s1)
    800046cc:	fbed                	bnez	a5,800046be <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046ce:	4785                	li	a5,1
    800046d0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046d2:	ffffd097          	auipc	ra,0xffffd
    800046d6:	2da080e7          	jalr	730(ra) # 800019ac <myproc>
    800046da:	591c                	lw	a5,48(a0)
    800046dc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046de:	854a                	mv	a0,s2
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	5aa080e7          	jalr	1450(ra) # 80000c8a <release>
}
    800046e8:	60e2                	ld	ra,24(sp)
    800046ea:	6442                	ld	s0,16(sp)
    800046ec:	64a2                	ld	s1,8(sp)
    800046ee:	6902                	ld	s2,0(sp)
    800046f0:	6105                	addi	sp,sp,32
    800046f2:	8082                	ret

00000000800046f4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046f4:	1101                	addi	sp,sp,-32
    800046f6:	ec06                	sd	ra,24(sp)
    800046f8:	e822                	sd	s0,16(sp)
    800046fa:	e426                	sd	s1,8(sp)
    800046fc:	e04a                	sd	s2,0(sp)
    800046fe:	1000                	addi	s0,sp,32
    80004700:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004702:	00850913          	addi	s2,a0,8
    80004706:	854a                	mv	a0,s2
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	4ce080e7          	jalr	1230(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004710:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004714:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004718:	8526                	mv	a0,s1
    8000471a:	ffffe097          	auipc	ra,0xffffe
    8000471e:	9c2080e7          	jalr	-1598(ra) # 800020dc <wakeup>
  release(&lk->lk);
    80004722:	854a                	mv	a0,s2
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	566080e7          	jalr	1382(ra) # 80000c8a <release>
}
    8000472c:	60e2                	ld	ra,24(sp)
    8000472e:	6442                	ld	s0,16(sp)
    80004730:	64a2                	ld	s1,8(sp)
    80004732:	6902                	ld	s2,0(sp)
    80004734:	6105                	addi	sp,sp,32
    80004736:	8082                	ret

0000000080004738 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004738:	7179                	addi	sp,sp,-48
    8000473a:	f406                	sd	ra,40(sp)
    8000473c:	f022                	sd	s0,32(sp)
    8000473e:	ec26                	sd	s1,24(sp)
    80004740:	e84a                	sd	s2,16(sp)
    80004742:	e44e                	sd	s3,8(sp)
    80004744:	1800                	addi	s0,sp,48
    80004746:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004748:	00850913          	addi	s2,a0,8
    8000474c:	854a                	mv	a0,s2
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	488080e7          	jalr	1160(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004756:	409c                	lw	a5,0(s1)
    80004758:	ef99                	bnez	a5,80004776 <holdingsleep+0x3e>
    8000475a:	4481                	li	s1,0
  release(&lk->lk);
    8000475c:	854a                	mv	a0,s2
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
  return r;
}
    80004766:	8526                	mv	a0,s1
    80004768:	70a2                	ld	ra,40(sp)
    8000476a:	7402                	ld	s0,32(sp)
    8000476c:	64e2                	ld	s1,24(sp)
    8000476e:	6942                	ld	s2,16(sp)
    80004770:	69a2                	ld	s3,8(sp)
    80004772:	6145                	addi	sp,sp,48
    80004774:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004776:	0284a983          	lw	s3,40(s1)
    8000477a:	ffffd097          	auipc	ra,0xffffd
    8000477e:	232080e7          	jalr	562(ra) # 800019ac <myproc>
    80004782:	5904                	lw	s1,48(a0)
    80004784:	413484b3          	sub	s1,s1,s3
    80004788:	0014b493          	seqz	s1,s1
    8000478c:	bfc1                	j	8000475c <holdingsleep+0x24>

000000008000478e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000478e:	1141                	addi	sp,sp,-16
    80004790:	e406                	sd	ra,8(sp)
    80004792:	e022                	sd	s0,0(sp)
    80004794:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004796:	00004597          	auipc	a1,0x4
    8000479a:	f1258593          	addi	a1,a1,-238 # 800086a8 <syscalls+0x258>
    8000479e:	0001d517          	auipc	a0,0x1d
    800047a2:	2fa50513          	addi	a0,a0,762 # 80021a98 <ftable>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	3a0080e7          	jalr	928(ra) # 80000b46 <initlock>
}
    800047ae:	60a2                	ld	ra,8(sp)
    800047b0:	6402                	ld	s0,0(sp)
    800047b2:	0141                	addi	sp,sp,16
    800047b4:	8082                	ret

00000000800047b6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047b6:	1101                	addi	sp,sp,-32
    800047b8:	ec06                	sd	ra,24(sp)
    800047ba:	e822                	sd	s0,16(sp)
    800047bc:	e426                	sd	s1,8(sp)
    800047be:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047c0:	0001d517          	auipc	a0,0x1d
    800047c4:	2d850513          	addi	a0,a0,728 # 80021a98 <ftable>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	40e080e7          	jalr	1038(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047d0:	0001d497          	auipc	s1,0x1d
    800047d4:	2e048493          	addi	s1,s1,736 # 80021ab0 <ftable+0x18>
    800047d8:	0001e717          	auipc	a4,0x1e
    800047dc:	27870713          	addi	a4,a4,632 # 80022a50 <disk>
    if(f->ref == 0){
    800047e0:	40dc                	lw	a5,4(s1)
    800047e2:	cf99                	beqz	a5,80004800 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047e4:	02848493          	addi	s1,s1,40
    800047e8:	fee49ce3          	bne	s1,a4,800047e0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047ec:	0001d517          	auipc	a0,0x1d
    800047f0:	2ac50513          	addi	a0,a0,684 # 80021a98 <ftable>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	496080e7          	jalr	1174(ra) # 80000c8a <release>
  return 0;
    800047fc:	4481                	li	s1,0
    800047fe:	a819                	j	80004814 <filealloc+0x5e>
      f->ref = 1;
    80004800:	4785                	li	a5,1
    80004802:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004804:	0001d517          	auipc	a0,0x1d
    80004808:	29450513          	addi	a0,a0,660 # 80021a98 <ftable>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	47e080e7          	jalr	1150(ra) # 80000c8a <release>
}
    80004814:	8526                	mv	a0,s1
    80004816:	60e2                	ld	ra,24(sp)
    80004818:	6442                	ld	s0,16(sp)
    8000481a:	64a2                	ld	s1,8(sp)
    8000481c:	6105                	addi	sp,sp,32
    8000481e:	8082                	ret

0000000080004820 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004820:	1101                	addi	sp,sp,-32
    80004822:	ec06                	sd	ra,24(sp)
    80004824:	e822                	sd	s0,16(sp)
    80004826:	e426                	sd	s1,8(sp)
    80004828:	1000                	addi	s0,sp,32
    8000482a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000482c:	0001d517          	auipc	a0,0x1d
    80004830:	26c50513          	addi	a0,a0,620 # 80021a98 <ftable>
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	3a2080e7          	jalr	930(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000483c:	40dc                	lw	a5,4(s1)
    8000483e:	02f05263          	blez	a5,80004862 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004842:	2785                	addiw	a5,a5,1
    80004844:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004846:	0001d517          	auipc	a0,0x1d
    8000484a:	25250513          	addi	a0,a0,594 # 80021a98 <ftable>
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	43c080e7          	jalr	1084(ra) # 80000c8a <release>
  return f;
}
    80004856:	8526                	mv	a0,s1
    80004858:	60e2                	ld	ra,24(sp)
    8000485a:	6442                	ld	s0,16(sp)
    8000485c:	64a2                	ld	s1,8(sp)
    8000485e:	6105                	addi	sp,sp,32
    80004860:	8082                	ret
    panic("filedup");
    80004862:	00004517          	auipc	a0,0x4
    80004866:	e4e50513          	addi	a0,a0,-434 # 800086b0 <syscalls+0x260>
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	cd6080e7          	jalr	-810(ra) # 80000540 <panic>

0000000080004872 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004872:	7139                	addi	sp,sp,-64
    80004874:	fc06                	sd	ra,56(sp)
    80004876:	f822                	sd	s0,48(sp)
    80004878:	f426                	sd	s1,40(sp)
    8000487a:	f04a                	sd	s2,32(sp)
    8000487c:	ec4e                	sd	s3,24(sp)
    8000487e:	e852                	sd	s4,16(sp)
    80004880:	e456                	sd	s5,8(sp)
    80004882:	0080                	addi	s0,sp,64
    80004884:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004886:	0001d517          	auipc	a0,0x1d
    8000488a:	21250513          	addi	a0,a0,530 # 80021a98 <ftable>
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	348080e7          	jalr	840(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004896:	40dc                	lw	a5,4(s1)
    80004898:	06f05163          	blez	a5,800048fa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000489c:	37fd                	addiw	a5,a5,-1
    8000489e:	0007871b          	sext.w	a4,a5
    800048a2:	c0dc                	sw	a5,4(s1)
    800048a4:	06e04363          	bgtz	a4,8000490a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048a8:	0004a903          	lw	s2,0(s1)
    800048ac:	0094ca83          	lbu	s5,9(s1)
    800048b0:	0104ba03          	ld	s4,16(s1)
    800048b4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048b8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048bc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048c0:	0001d517          	auipc	a0,0x1d
    800048c4:	1d850513          	addi	a0,a0,472 # 80021a98 <ftable>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	3c2080e7          	jalr	962(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800048d0:	4785                	li	a5,1
    800048d2:	04f90d63          	beq	s2,a5,8000492c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048d6:	3979                	addiw	s2,s2,-2
    800048d8:	4785                	li	a5,1
    800048da:	0527e063          	bltu	a5,s2,8000491a <fileclose+0xa8>
    begin_op();
    800048de:	00000097          	auipc	ra,0x0
    800048e2:	acc080e7          	jalr	-1332(ra) # 800043aa <begin_op>
    iput(ff.ip);
    800048e6:	854e                	mv	a0,s3
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	2b0080e7          	jalr	688(ra) # 80003b98 <iput>
    end_op();
    800048f0:	00000097          	auipc	ra,0x0
    800048f4:	b38080e7          	jalr	-1224(ra) # 80004428 <end_op>
    800048f8:	a00d                	j	8000491a <fileclose+0xa8>
    panic("fileclose");
    800048fa:	00004517          	auipc	a0,0x4
    800048fe:	dbe50513          	addi	a0,a0,-578 # 800086b8 <syscalls+0x268>
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	c3e080e7          	jalr	-962(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000490a:	0001d517          	auipc	a0,0x1d
    8000490e:	18e50513          	addi	a0,a0,398 # 80021a98 <ftable>
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	378080e7          	jalr	888(ra) # 80000c8a <release>
  }
}
    8000491a:	70e2                	ld	ra,56(sp)
    8000491c:	7442                	ld	s0,48(sp)
    8000491e:	74a2                	ld	s1,40(sp)
    80004920:	7902                	ld	s2,32(sp)
    80004922:	69e2                	ld	s3,24(sp)
    80004924:	6a42                	ld	s4,16(sp)
    80004926:	6aa2                	ld	s5,8(sp)
    80004928:	6121                	addi	sp,sp,64
    8000492a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000492c:	85d6                	mv	a1,s5
    8000492e:	8552                	mv	a0,s4
    80004930:	00000097          	auipc	ra,0x0
    80004934:	34c080e7          	jalr	844(ra) # 80004c7c <pipeclose>
    80004938:	b7cd                	j	8000491a <fileclose+0xa8>

000000008000493a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000493a:	715d                	addi	sp,sp,-80
    8000493c:	e486                	sd	ra,72(sp)
    8000493e:	e0a2                	sd	s0,64(sp)
    80004940:	fc26                	sd	s1,56(sp)
    80004942:	f84a                	sd	s2,48(sp)
    80004944:	f44e                	sd	s3,40(sp)
    80004946:	0880                	addi	s0,sp,80
    80004948:	84aa                	mv	s1,a0
    8000494a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000494c:	ffffd097          	auipc	ra,0xffffd
    80004950:	060080e7          	jalr	96(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004954:	409c                	lw	a5,0(s1)
    80004956:	37f9                	addiw	a5,a5,-2
    80004958:	4705                	li	a4,1
    8000495a:	04f76763          	bltu	a4,a5,800049a8 <filestat+0x6e>
    8000495e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004960:	6c88                	ld	a0,24(s1)
    80004962:	fffff097          	auipc	ra,0xfffff
    80004966:	07c080e7          	jalr	124(ra) # 800039de <ilock>
    stati(f->ip, &st);
    8000496a:	fb840593          	addi	a1,s0,-72
    8000496e:	6c88                	ld	a0,24(s1)
    80004970:	fffff097          	auipc	ra,0xfffff
    80004974:	2f8080e7          	jalr	760(ra) # 80003c68 <stati>
    iunlock(f->ip);
    80004978:	6c88                	ld	a0,24(s1)
    8000497a:	fffff097          	auipc	ra,0xfffff
    8000497e:	126080e7          	jalr	294(ra) # 80003aa0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004982:	46e1                	li	a3,24
    80004984:	fb840613          	addi	a2,s0,-72
    80004988:	85ce                	mv	a1,s3
    8000498a:	05093503          	ld	a0,80(s2)
    8000498e:	ffffd097          	auipc	ra,0xffffd
    80004992:	cde080e7          	jalr	-802(ra) # 8000166c <copyout>
    80004996:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000499a:	60a6                	ld	ra,72(sp)
    8000499c:	6406                	ld	s0,64(sp)
    8000499e:	74e2                	ld	s1,56(sp)
    800049a0:	7942                	ld	s2,48(sp)
    800049a2:	79a2                	ld	s3,40(sp)
    800049a4:	6161                	addi	sp,sp,80
    800049a6:	8082                	ret
  return -1;
    800049a8:	557d                	li	a0,-1
    800049aa:	bfc5                	j	8000499a <filestat+0x60>

00000000800049ac <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049ac:	7179                	addi	sp,sp,-48
    800049ae:	f406                	sd	ra,40(sp)
    800049b0:	f022                	sd	s0,32(sp)
    800049b2:	ec26                	sd	s1,24(sp)
    800049b4:	e84a                	sd	s2,16(sp)
    800049b6:	e44e                	sd	s3,8(sp)
    800049b8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049ba:	00854783          	lbu	a5,8(a0)
    800049be:	c3d5                	beqz	a5,80004a62 <fileread+0xb6>
    800049c0:	84aa                	mv	s1,a0
    800049c2:	89ae                	mv	s3,a1
    800049c4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049c6:	411c                	lw	a5,0(a0)
    800049c8:	4705                	li	a4,1
    800049ca:	04e78963          	beq	a5,a4,80004a1c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049ce:	470d                	li	a4,3
    800049d0:	04e78d63          	beq	a5,a4,80004a2a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049d4:	4709                	li	a4,2
    800049d6:	06e79e63          	bne	a5,a4,80004a52 <fileread+0xa6>
    ilock(f->ip);
    800049da:	6d08                	ld	a0,24(a0)
    800049dc:	fffff097          	auipc	ra,0xfffff
    800049e0:	002080e7          	jalr	2(ra) # 800039de <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049e4:	874a                	mv	a4,s2
    800049e6:	5094                	lw	a3,32(s1)
    800049e8:	864e                	mv	a2,s3
    800049ea:	4585                	li	a1,1
    800049ec:	6c88                	ld	a0,24(s1)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	2a4080e7          	jalr	676(ra) # 80003c92 <readi>
    800049f6:	892a                	mv	s2,a0
    800049f8:	00a05563          	blez	a0,80004a02 <fileread+0x56>
      f->off += r;
    800049fc:	509c                	lw	a5,32(s1)
    800049fe:	9fa9                	addw	a5,a5,a0
    80004a00:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a02:	6c88                	ld	a0,24(s1)
    80004a04:	fffff097          	auipc	ra,0xfffff
    80004a08:	09c080e7          	jalr	156(ra) # 80003aa0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a0c:	854a                	mv	a0,s2
    80004a0e:	70a2                	ld	ra,40(sp)
    80004a10:	7402                	ld	s0,32(sp)
    80004a12:	64e2                	ld	s1,24(sp)
    80004a14:	6942                	ld	s2,16(sp)
    80004a16:	69a2                	ld	s3,8(sp)
    80004a18:	6145                	addi	sp,sp,48
    80004a1a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a1c:	6908                	ld	a0,16(a0)
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	3c6080e7          	jalr	966(ra) # 80004de4 <piperead>
    80004a26:	892a                	mv	s2,a0
    80004a28:	b7d5                	j	80004a0c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a2a:	02451783          	lh	a5,36(a0)
    80004a2e:	03079693          	slli	a3,a5,0x30
    80004a32:	92c1                	srli	a3,a3,0x30
    80004a34:	4725                	li	a4,9
    80004a36:	02d76863          	bltu	a4,a3,80004a66 <fileread+0xba>
    80004a3a:	0792                	slli	a5,a5,0x4
    80004a3c:	0001d717          	auipc	a4,0x1d
    80004a40:	fbc70713          	addi	a4,a4,-68 # 800219f8 <devsw>
    80004a44:	97ba                	add	a5,a5,a4
    80004a46:	639c                	ld	a5,0(a5)
    80004a48:	c38d                	beqz	a5,80004a6a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a4a:	4505                	li	a0,1
    80004a4c:	9782                	jalr	a5
    80004a4e:	892a                	mv	s2,a0
    80004a50:	bf75                	j	80004a0c <fileread+0x60>
    panic("fileread");
    80004a52:	00004517          	auipc	a0,0x4
    80004a56:	c7650513          	addi	a0,a0,-906 # 800086c8 <syscalls+0x278>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	ae6080e7          	jalr	-1306(ra) # 80000540 <panic>
    return -1;
    80004a62:	597d                	li	s2,-1
    80004a64:	b765                	j	80004a0c <fileread+0x60>
      return -1;
    80004a66:	597d                	li	s2,-1
    80004a68:	b755                	j	80004a0c <fileread+0x60>
    80004a6a:	597d                	li	s2,-1
    80004a6c:	b745                	j	80004a0c <fileread+0x60>

0000000080004a6e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a6e:	715d                	addi	sp,sp,-80
    80004a70:	e486                	sd	ra,72(sp)
    80004a72:	e0a2                	sd	s0,64(sp)
    80004a74:	fc26                	sd	s1,56(sp)
    80004a76:	f84a                	sd	s2,48(sp)
    80004a78:	f44e                	sd	s3,40(sp)
    80004a7a:	f052                	sd	s4,32(sp)
    80004a7c:	ec56                	sd	s5,24(sp)
    80004a7e:	e85a                	sd	s6,16(sp)
    80004a80:	e45e                	sd	s7,8(sp)
    80004a82:	e062                	sd	s8,0(sp)
    80004a84:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a86:	00954783          	lbu	a5,9(a0)
    80004a8a:	10078663          	beqz	a5,80004b96 <filewrite+0x128>
    80004a8e:	892a                	mv	s2,a0
    80004a90:	8b2e                	mv	s6,a1
    80004a92:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a94:	411c                	lw	a5,0(a0)
    80004a96:	4705                	li	a4,1
    80004a98:	02e78263          	beq	a5,a4,80004abc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a9c:	470d                	li	a4,3
    80004a9e:	02e78663          	beq	a5,a4,80004aca <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004aa2:	4709                	li	a4,2
    80004aa4:	0ee79163          	bne	a5,a4,80004b86 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004aa8:	0ac05d63          	blez	a2,80004b62 <filewrite+0xf4>
    int i = 0;
    80004aac:	4981                	li	s3,0
    80004aae:	6b85                	lui	s7,0x1
    80004ab0:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ab4:	6c05                	lui	s8,0x1
    80004ab6:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004aba:	a861                	j	80004b52 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004abc:	6908                	ld	a0,16(a0)
    80004abe:	00000097          	auipc	ra,0x0
    80004ac2:	22e080e7          	jalr	558(ra) # 80004cec <pipewrite>
    80004ac6:	8a2a                	mv	s4,a0
    80004ac8:	a045                	j	80004b68 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004aca:	02451783          	lh	a5,36(a0)
    80004ace:	03079693          	slli	a3,a5,0x30
    80004ad2:	92c1                	srli	a3,a3,0x30
    80004ad4:	4725                	li	a4,9
    80004ad6:	0cd76263          	bltu	a4,a3,80004b9a <filewrite+0x12c>
    80004ada:	0792                	slli	a5,a5,0x4
    80004adc:	0001d717          	auipc	a4,0x1d
    80004ae0:	f1c70713          	addi	a4,a4,-228 # 800219f8 <devsw>
    80004ae4:	97ba                	add	a5,a5,a4
    80004ae6:	679c                	ld	a5,8(a5)
    80004ae8:	cbdd                	beqz	a5,80004b9e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004aea:	4505                	li	a0,1
    80004aec:	9782                	jalr	a5
    80004aee:	8a2a                	mv	s4,a0
    80004af0:	a8a5                	j	80004b68 <filewrite+0xfa>
    80004af2:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004af6:	00000097          	auipc	ra,0x0
    80004afa:	8b4080e7          	jalr	-1868(ra) # 800043aa <begin_op>
      ilock(f->ip);
    80004afe:	01893503          	ld	a0,24(s2)
    80004b02:	fffff097          	auipc	ra,0xfffff
    80004b06:	edc080e7          	jalr	-292(ra) # 800039de <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b0a:	8756                	mv	a4,s5
    80004b0c:	02092683          	lw	a3,32(s2)
    80004b10:	01698633          	add	a2,s3,s6
    80004b14:	4585                	li	a1,1
    80004b16:	01893503          	ld	a0,24(s2)
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	270080e7          	jalr	624(ra) # 80003d8a <writei>
    80004b22:	84aa                	mv	s1,a0
    80004b24:	00a05763          	blez	a0,80004b32 <filewrite+0xc4>
        f->off += r;
    80004b28:	02092783          	lw	a5,32(s2)
    80004b2c:	9fa9                	addw	a5,a5,a0
    80004b2e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b32:	01893503          	ld	a0,24(s2)
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	f6a080e7          	jalr	-150(ra) # 80003aa0 <iunlock>
      end_op();
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	8ea080e7          	jalr	-1814(ra) # 80004428 <end_op>

      if(r != n1){
    80004b46:	009a9f63          	bne	s5,s1,80004b64 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b4a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b4e:	0149db63          	bge	s3,s4,80004b64 <filewrite+0xf6>
      int n1 = n - i;
    80004b52:	413a04bb          	subw	s1,s4,s3
    80004b56:	0004879b          	sext.w	a5,s1
    80004b5a:	f8fbdce3          	bge	s7,a5,80004af2 <filewrite+0x84>
    80004b5e:	84e2                	mv	s1,s8
    80004b60:	bf49                	j	80004af2 <filewrite+0x84>
    int i = 0;
    80004b62:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b64:	013a1f63          	bne	s4,s3,80004b82 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b68:	8552                	mv	a0,s4
    80004b6a:	60a6                	ld	ra,72(sp)
    80004b6c:	6406                	ld	s0,64(sp)
    80004b6e:	74e2                	ld	s1,56(sp)
    80004b70:	7942                	ld	s2,48(sp)
    80004b72:	79a2                	ld	s3,40(sp)
    80004b74:	7a02                	ld	s4,32(sp)
    80004b76:	6ae2                	ld	s5,24(sp)
    80004b78:	6b42                	ld	s6,16(sp)
    80004b7a:	6ba2                	ld	s7,8(sp)
    80004b7c:	6c02                	ld	s8,0(sp)
    80004b7e:	6161                	addi	sp,sp,80
    80004b80:	8082                	ret
    ret = (i == n ? n : -1);
    80004b82:	5a7d                	li	s4,-1
    80004b84:	b7d5                	j	80004b68 <filewrite+0xfa>
    panic("filewrite");
    80004b86:	00004517          	auipc	a0,0x4
    80004b8a:	b5250513          	addi	a0,a0,-1198 # 800086d8 <syscalls+0x288>
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	9b2080e7          	jalr	-1614(ra) # 80000540 <panic>
    return -1;
    80004b96:	5a7d                	li	s4,-1
    80004b98:	bfc1                	j	80004b68 <filewrite+0xfa>
      return -1;
    80004b9a:	5a7d                	li	s4,-1
    80004b9c:	b7f1                	j	80004b68 <filewrite+0xfa>
    80004b9e:	5a7d                	li	s4,-1
    80004ba0:	b7e1                	j	80004b68 <filewrite+0xfa>

0000000080004ba2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ba2:	7179                	addi	sp,sp,-48
    80004ba4:	f406                	sd	ra,40(sp)
    80004ba6:	f022                	sd	s0,32(sp)
    80004ba8:	ec26                	sd	s1,24(sp)
    80004baa:	e84a                	sd	s2,16(sp)
    80004bac:	e44e                	sd	s3,8(sp)
    80004bae:	e052                	sd	s4,0(sp)
    80004bb0:	1800                	addi	s0,sp,48
    80004bb2:	84aa                	mv	s1,a0
    80004bb4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bb6:	0005b023          	sd	zero,0(a1)
    80004bba:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bbe:	00000097          	auipc	ra,0x0
    80004bc2:	bf8080e7          	jalr	-1032(ra) # 800047b6 <filealloc>
    80004bc6:	e088                	sd	a0,0(s1)
    80004bc8:	c551                	beqz	a0,80004c54 <pipealloc+0xb2>
    80004bca:	00000097          	auipc	ra,0x0
    80004bce:	bec080e7          	jalr	-1044(ra) # 800047b6 <filealloc>
    80004bd2:	00aa3023          	sd	a0,0(s4)
    80004bd6:	c92d                	beqz	a0,80004c48 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	f0e080e7          	jalr	-242(ra) # 80000ae6 <kalloc>
    80004be0:	892a                	mv	s2,a0
    80004be2:	c125                	beqz	a0,80004c42 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004be4:	4985                	li	s3,1
    80004be6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bea:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bee:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bf2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bf6:	00004597          	auipc	a1,0x4
    80004bfa:	af258593          	addi	a1,a1,-1294 # 800086e8 <syscalls+0x298>
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	f48080e7          	jalr	-184(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c06:	609c                	ld	a5,0(s1)
    80004c08:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c0c:	609c                	ld	a5,0(s1)
    80004c0e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c12:	609c                	ld	a5,0(s1)
    80004c14:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c18:	609c                	ld	a5,0(s1)
    80004c1a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c1e:	000a3783          	ld	a5,0(s4)
    80004c22:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c26:	000a3783          	ld	a5,0(s4)
    80004c2a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c2e:	000a3783          	ld	a5,0(s4)
    80004c32:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c36:	000a3783          	ld	a5,0(s4)
    80004c3a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c3e:	4501                	li	a0,0
    80004c40:	a025                	j	80004c68 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c42:	6088                	ld	a0,0(s1)
    80004c44:	e501                	bnez	a0,80004c4c <pipealloc+0xaa>
    80004c46:	a039                	j	80004c54 <pipealloc+0xb2>
    80004c48:	6088                	ld	a0,0(s1)
    80004c4a:	c51d                	beqz	a0,80004c78 <pipealloc+0xd6>
    fileclose(*f0);
    80004c4c:	00000097          	auipc	ra,0x0
    80004c50:	c26080e7          	jalr	-986(ra) # 80004872 <fileclose>
  if(*f1)
    80004c54:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c58:	557d                	li	a0,-1
  if(*f1)
    80004c5a:	c799                	beqz	a5,80004c68 <pipealloc+0xc6>
    fileclose(*f1);
    80004c5c:	853e                	mv	a0,a5
    80004c5e:	00000097          	auipc	ra,0x0
    80004c62:	c14080e7          	jalr	-1004(ra) # 80004872 <fileclose>
  return -1;
    80004c66:	557d                	li	a0,-1
}
    80004c68:	70a2                	ld	ra,40(sp)
    80004c6a:	7402                	ld	s0,32(sp)
    80004c6c:	64e2                	ld	s1,24(sp)
    80004c6e:	6942                	ld	s2,16(sp)
    80004c70:	69a2                	ld	s3,8(sp)
    80004c72:	6a02                	ld	s4,0(sp)
    80004c74:	6145                	addi	sp,sp,48
    80004c76:	8082                	ret
  return -1;
    80004c78:	557d                	li	a0,-1
    80004c7a:	b7fd                	j	80004c68 <pipealloc+0xc6>

0000000080004c7c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c7c:	1101                	addi	sp,sp,-32
    80004c7e:	ec06                	sd	ra,24(sp)
    80004c80:	e822                	sd	s0,16(sp)
    80004c82:	e426                	sd	s1,8(sp)
    80004c84:	e04a                	sd	s2,0(sp)
    80004c86:	1000                	addi	s0,sp,32
    80004c88:	84aa                	mv	s1,a0
    80004c8a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	f4a080e7          	jalr	-182(ra) # 80000bd6 <acquire>
  if(writable){
    80004c94:	02090d63          	beqz	s2,80004cce <pipeclose+0x52>
    pi->writeopen = 0;
    80004c98:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c9c:	21848513          	addi	a0,s1,536
    80004ca0:	ffffd097          	auipc	ra,0xffffd
    80004ca4:	43c080e7          	jalr	1084(ra) # 800020dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ca8:	2204b783          	ld	a5,544(s1)
    80004cac:	eb95                	bnez	a5,80004ce0 <pipeclose+0x64>
    release(&pi->lock);
    80004cae:	8526                	mv	a0,s1
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	fda080e7          	jalr	-38(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004cb8:	8526                	mv	a0,s1
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	d2e080e7          	jalr	-722(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004cc2:	60e2                	ld	ra,24(sp)
    80004cc4:	6442                	ld	s0,16(sp)
    80004cc6:	64a2                	ld	s1,8(sp)
    80004cc8:	6902                	ld	s2,0(sp)
    80004cca:	6105                	addi	sp,sp,32
    80004ccc:	8082                	ret
    pi->readopen = 0;
    80004cce:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cd2:	21c48513          	addi	a0,s1,540
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	406080e7          	jalr	1030(ra) # 800020dc <wakeup>
    80004cde:	b7e9                	j	80004ca8 <pipeclose+0x2c>
    release(&pi->lock);
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	fa8080e7          	jalr	-88(ra) # 80000c8a <release>
}
    80004cea:	bfe1                	j	80004cc2 <pipeclose+0x46>

0000000080004cec <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cec:	711d                	addi	sp,sp,-96
    80004cee:	ec86                	sd	ra,88(sp)
    80004cf0:	e8a2                	sd	s0,80(sp)
    80004cf2:	e4a6                	sd	s1,72(sp)
    80004cf4:	e0ca                	sd	s2,64(sp)
    80004cf6:	fc4e                	sd	s3,56(sp)
    80004cf8:	f852                	sd	s4,48(sp)
    80004cfa:	f456                	sd	s5,40(sp)
    80004cfc:	f05a                	sd	s6,32(sp)
    80004cfe:	ec5e                	sd	s7,24(sp)
    80004d00:	e862                	sd	s8,16(sp)
    80004d02:	1080                	addi	s0,sp,96
    80004d04:	84aa                	mv	s1,a0
    80004d06:	8aae                	mv	s5,a1
    80004d08:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d0a:	ffffd097          	auipc	ra,0xffffd
    80004d0e:	ca2080e7          	jalr	-862(ra) # 800019ac <myproc>
    80004d12:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d14:	8526                	mv	a0,s1
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	ec0080e7          	jalr	-320(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d1e:	0b405663          	blez	s4,80004dca <pipewrite+0xde>
  int i = 0;
    80004d22:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d24:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d26:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d2a:	21c48b93          	addi	s7,s1,540
    80004d2e:	a089                	j	80004d70 <pipewrite+0x84>
      release(&pi->lock);
    80004d30:	8526                	mv	a0,s1
    80004d32:	ffffc097          	auipc	ra,0xffffc
    80004d36:	f58080e7          	jalr	-168(ra) # 80000c8a <release>
      return -1;
    80004d3a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d3c:	854a                	mv	a0,s2
    80004d3e:	60e6                	ld	ra,88(sp)
    80004d40:	6446                	ld	s0,80(sp)
    80004d42:	64a6                	ld	s1,72(sp)
    80004d44:	6906                	ld	s2,64(sp)
    80004d46:	79e2                	ld	s3,56(sp)
    80004d48:	7a42                	ld	s4,48(sp)
    80004d4a:	7aa2                	ld	s5,40(sp)
    80004d4c:	7b02                	ld	s6,32(sp)
    80004d4e:	6be2                	ld	s7,24(sp)
    80004d50:	6c42                	ld	s8,16(sp)
    80004d52:	6125                	addi	sp,sp,96
    80004d54:	8082                	ret
      wakeup(&pi->nread);
    80004d56:	8562                	mv	a0,s8
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	384080e7          	jalr	900(ra) # 800020dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d60:	85a6                	mv	a1,s1
    80004d62:	855e                	mv	a0,s7
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	314080e7          	jalr	788(ra) # 80002078 <sleep>
  while(i < n){
    80004d6c:	07495063          	bge	s2,s4,80004dcc <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004d70:	2204a783          	lw	a5,544(s1)
    80004d74:	dfd5                	beqz	a5,80004d30 <pipewrite+0x44>
    80004d76:	854e                	mv	a0,s3
    80004d78:	ffffd097          	auipc	ra,0xffffd
    80004d7c:	5b4080e7          	jalr	1460(ra) # 8000232c <killed>
    80004d80:	f945                	bnez	a0,80004d30 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d82:	2184a783          	lw	a5,536(s1)
    80004d86:	21c4a703          	lw	a4,540(s1)
    80004d8a:	2007879b          	addiw	a5,a5,512
    80004d8e:	fcf704e3          	beq	a4,a5,80004d56 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d92:	4685                	li	a3,1
    80004d94:	01590633          	add	a2,s2,s5
    80004d98:	faf40593          	addi	a1,s0,-81
    80004d9c:	0509b503          	ld	a0,80(s3)
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	958080e7          	jalr	-1704(ra) # 800016f8 <copyin>
    80004da8:	03650263          	beq	a0,s6,80004dcc <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dac:	21c4a783          	lw	a5,540(s1)
    80004db0:	0017871b          	addiw	a4,a5,1
    80004db4:	20e4ae23          	sw	a4,540(s1)
    80004db8:	1ff7f793          	andi	a5,a5,511
    80004dbc:	97a6                	add	a5,a5,s1
    80004dbe:	faf44703          	lbu	a4,-81(s0)
    80004dc2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004dc6:	2905                	addiw	s2,s2,1
    80004dc8:	b755                	j	80004d6c <pipewrite+0x80>
  int i = 0;
    80004dca:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004dcc:	21848513          	addi	a0,s1,536
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	30c080e7          	jalr	780(ra) # 800020dc <wakeup>
  release(&pi->lock);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	ffffc097          	auipc	ra,0xffffc
    80004dde:	eb0080e7          	jalr	-336(ra) # 80000c8a <release>
  return i;
    80004de2:	bfa9                	j	80004d3c <pipewrite+0x50>

0000000080004de4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004de4:	715d                	addi	sp,sp,-80
    80004de6:	e486                	sd	ra,72(sp)
    80004de8:	e0a2                	sd	s0,64(sp)
    80004dea:	fc26                	sd	s1,56(sp)
    80004dec:	f84a                	sd	s2,48(sp)
    80004dee:	f44e                	sd	s3,40(sp)
    80004df0:	f052                	sd	s4,32(sp)
    80004df2:	ec56                	sd	s5,24(sp)
    80004df4:	e85a                	sd	s6,16(sp)
    80004df6:	0880                	addi	s0,sp,80
    80004df8:	84aa                	mv	s1,a0
    80004dfa:	892e                	mv	s2,a1
    80004dfc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	bae080e7          	jalr	-1106(ra) # 800019ac <myproc>
    80004e06:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e08:	8526                	mv	a0,s1
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	dcc080e7          	jalr	-564(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e12:	2184a703          	lw	a4,536(s1)
    80004e16:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e1a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e1e:	02f71763          	bne	a4,a5,80004e4c <piperead+0x68>
    80004e22:	2244a783          	lw	a5,548(s1)
    80004e26:	c39d                	beqz	a5,80004e4c <piperead+0x68>
    if(killed(pr)){
    80004e28:	8552                	mv	a0,s4
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	502080e7          	jalr	1282(ra) # 8000232c <killed>
    80004e32:	e949                	bnez	a0,80004ec4 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e34:	85a6                	mv	a1,s1
    80004e36:	854e                	mv	a0,s3
    80004e38:	ffffd097          	auipc	ra,0xffffd
    80004e3c:	240080e7          	jalr	576(ra) # 80002078 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e40:	2184a703          	lw	a4,536(s1)
    80004e44:	21c4a783          	lw	a5,540(s1)
    80004e48:	fcf70de3          	beq	a4,a5,80004e22 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e4c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e4e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e50:	05505463          	blez	s5,80004e98 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004e54:	2184a783          	lw	a5,536(s1)
    80004e58:	21c4a703          	lw	a4,540(s1)
    80004e5c:	02f70e63          	beq	a4,a5,80004e98 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e60:	0017871b          	addiw	a4,a5,1
    80004e64:	20e4ac23          	sw	a4,536(s1)
    80004e68:	1ff7f793          	andi	a5,a5,511
    80004e6c:	97a6                	add	a5,a5,s1
    80004e6e:	0187c783          	lbu	a5,24(a5)
    80004e72:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e76:	4685                	li	a3,1
    80004e78:	fbf40613          	addi	a2,s0,-65
    80004e7c:	85ca                	mv	a1,s2
    80004e7e:	050a3503          	ld	a0,80(s4)
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	7ea080e7          	jalr	2026(ra) # 8000166c <copyout>
    80004e8a:	01650763          	beq	a0,s6,80004e98 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e8e:	2985                	addiw	s3,s3,1
    80004e90:	0905                	addi	s2,s2,1
    80004e92:	fd3a91e3          	bne	s5,s3,80004e54 <piperead+0x70>
    80004e96:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e98:	21c48513          	addi	a0,s1,540
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	240080e7          	jalr	576(ra) # 800020dc <wakeup>
  release(&pi->lock);
    80004ea4:	8526                	mv	a0,s1
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	de4080e7          	jalr	-540(ra) # 80000c8a <release>
  return i;
}
    80004eae:	854e                	mv	a0,s3
    80004eb0:	60a6                	ld	ra,72(sp)
    80004eb2:	6406                	ld	s0,64(sp)
    80004eb4:	74e2                	ld	s1,56(sp)
    80004eb6:	7942                	ld	s2,48(sp)
    80004eb8:	79a2                	ld	s3,40(sp)
    80004eba:	7a02                	ld	s4,32(sp)
    80004ebc:	6ae2                	ld	s5,24(sp)
    80004ebe:	6b42                	ld	s6,16(sp)
    80004ec0:	6161                	addi	sp,sp,80
    80004ec2:	8082                	ret
      release(&pi->lock);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	dc4080e7          	jalr	-572(ra) # 80000c8a <release>
      return -1;
    80004ece:	59fd                	li	s3,-1
    80004ed0:	bff9                	j	80004eae <piperead+0xca>

0000000080004ed2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ed2:	1141                	addi	sp,sp,-16
    80004ed4:	e422                	sd	s0,8(sp)
    80004ed6:	0800                	addi	s0,sp,16
    80004ed8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004eda:	8905                	andi	a0,a0,1
    80004edc:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004ede:	8b89                	andi	a5,a5,2
    80004ee0:	c399                	beqz	a5,80004ee6 <flags2perm+0x14>
      perm |= PTE_W;
    80004ee2:	00456513          	ori	a0,a0,4
    return perm;
}
    80004ee6:	6422                	ld	s0,8(sp)
    80004ee8:	0141                	addi	sp,sp,16
    80004eea:	8082                	ret

0000000080004eec <exec>:

int
exec(char *path, char **argv)
{
    80004eec:	de010113          	addi	sp,sp,-544
    80004ef0:	20113c23          	sd	ra,536(sp)
    80004ef4:	20813823          	sd	s0,528(sp)
    80004ef8:	20913423          	sd	s1,520(sp)
    80004efc:	21213023          	sd	s2,512(sp)
    80004f00:	ffce                	sd	s3,504(sp)
    80004f02:	fbd2                	sd	s4,496(sp)
    80004f04:	f7d6                	sd	s5,488(sp)
    80004f06:	f3da                	sd	s6,480(sp)
    80004f08:	efde                	sd	s7,472(sp)
    80004f0a:	ebe2                	sd	s8,464(sp)
    80004f0c:	e7e6                	sd	s9,456(sp)
    80004f0e:	e3ea                	sd	s10,448(sp)
    80004f10:	ff6e                	sd	s11,440(sp)
    80004f12:	1400                	addi	s0,sp,544
    80004f14:	892a                	mv	s2,a0
    80004f16:	dea43423          	sd	a0,-536(s0)
    80004f1a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f1e:	ffffd097          	auipc	ra,0xffffd
    80004f22:	a8e080e7          	jalr	-1394(ra) # 800019ac <myproc>
    80004f26:	84aa                	mv	s1,a0

  begin_op();
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	482080e7          	jalr	1154(ra) # 800043aa <begin_op>

  if((ip = namei(path)) == 0){
    80004f30:	854a                	mv	a0,s2
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	258080e7          	jalr	600(ra) # 8000418a <namei>
    80004f3a:	c93d                	beqz	a0,80004fb0 <exec+0xc4>
    80004f3c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	aa0080e7          	jalr	-1376(ra) # 800039de <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f46:	04000713          	li	a4,64
    80004f4a:	4681                	li	a3,0
    80004f4c:	e5040613          	addi	a2,s0,-432
    80004f50:	4581                	li	a1,0
    80004f52:	8556                	mv	a0,s5
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	d3e080e7          	jalr	-706(ra) # 80003c92 <readi>
    80004f5c:	04000793          	li	a5,64
    80004f60:	00f51a63          	bne	a0,a5,80004f74 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f64:	e5042703          	lw	a4,-432(s0)
    80004f68:	464c47b7          	lui	a5,0x464c4
    80004f6c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f70:	04f70663          	beq	a4,a5,80004fbc <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f74:	8556                	mv	a0,s5
    80004f76:	fffff097          	auipc	ra,0xfffff
    80004f7a:	cca080e7          	jalr	-822(ra) # 80003c40 <iunlockput>
    end_op();
    80004f7e:	fffff097          	auipc	ra,0xfffff
    80004f82:	4aa080e7          	jalr	1194(ra) # 80004428 <end_op>
  }
  return -1;
    80004f86:	557d                	li	a0,-1
}
    80004f88:	21813083          	ld	ra,536(sp)
    80004f8c:	21013403          	ld	s0,528(sp)
    80004f90:	20813483          	ld	s1,520(sp)
    80004f94:	20013903          	ld	s2,512(sp)
    80004f98:	79fe                	ld	s3,504(sp)
    80004f9a:	7a5e                	ld	s4,496(sp)
    80004f9c:	7abe                	ld	s5,488(sp)
    80004f9e:	7b1e                	ld	s6,480(sp)
    80004fa0:	6bfe                	ld	s7,472(sp)
    80004fa2:	6c5e                	ld	s8,464(sp)
    80004fa4:	6cbe                	ld	s9,456(sp)
    80004fa6:	6d1e                	ld	s10,448(sp)
    80004fa8:	7dfa                	ld	s11,440(sp)
    80004faa:	22010113          	addi	sp,sp,544
    80004fae:	8082                	ret
    end_op();
    80004fb0:	fffff097          	auipc	ra,0xfffff
    80004fb4:	478080e7          	jalr	1144(ra) # 80004428 <end_op>
    return -1;
    80004fb8:	557d                	li	a0,-1
    80004fba:	b7f9                	j	80004f88 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fbc:	8526                	mv	a0,s1
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	ab2080e7          	jalr	-1358(ra) # 80001a70 <proc_pagetable>
    80004fc6:	8b2a                	mv	s6,a0
    80004fc8:	d555                	beqz	a0,80004f74 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fca:	e7042783          	lw	a5,-400(s0)
    80004fce:	e8845703          	lhu	a4,-376(s0)
    80004fd2:	c735                	beqz	a4,8000503e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fd4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fda:	6a05                	lui	s4,0x1
    80004fdc:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004fe0:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004fe4:	6d85                	lui	s11,0x1
    80004fe6:	7d7d                	lui	s10,0xfffff
    80004fe8:	ac3d                	j	80005226 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fea:	00003517          	auipc	a0,0x3
    80004fee:	70650513          	addi	a0,a0,1798 # 800086f0 <syscalls+0x2a0>
    80004ff2:	ffffb097          	auipc	ra,0xffffb
    80004ff6:	54e080e7          	jalr	1358(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ffa:	874a                	mv	a4,s2
    80004ffc:	009c86bb          	addw	a3,s9,s1
    80005000:	4581                	li	a1,0
    80005002:	8556                	mv	a0,s5
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	c8e080e7          	jalr	-882(ra) # 80003c92 <readi>
    8000500c:	2501                	sext.w	a0,a0
    8000500e:	1aa91963          	bne	s2,a0,800051c0 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005012:	009d84bb          	addw	s1,s11,s1
    80005016:	013d09bb          	addw	s3,s10,s3
    8000501a:	1f74f663          	bgeu	s1,s7,80005206 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    8000501e:	02049593          	slli	a1,s1,0x20
    80005022:	9181                	srli	a1,a1,0x20
    80005024:	95e2                	add	a1,a1,s8
    80005026:	855a                	mv	a0,s6
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	034080e7          	jalr	52(ra) # 8000105c <walkaddr>
    80005030:	862a                	mv	a2,a0
    if(pa == 0)
    80005032:	dd45                	beqz	a0,80004fea <exec+0xfe>
      n = PGSIZE;
    80005034:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005036:	fd49f2e3          	bgeu	s3,s4,80004ffa <exec+0x10e>
      n = sz - i;
    8000503a:	894e                	mv	s2,s3
    8000503c:	bf7d                	j	80004ffa <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000503e:	4901                	li	s2,0
  iunlockput(ip);
    80005040:	8556                	mv	a0,s5
    80005042:	fffff097          	auipc	ra,0xfffff
    80005046:	bfe080e7          	jalr	-1026(ra) # 80003c40 <iunlockput>
  end_op();
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	3de080e7          	jalr	990(ra) # 80004428 <end_op>
  p = myproc();
    80005052:	ffffd097          	auipc	ra,0xffffd
    80005056:	95a080e7          	jalr	-1702(ra) # 800019ac <myproc>
    8000505a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000505c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005060:	6785                	lui	a5,0x1
    80005062:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005064:	97ca                	add	a5,a5,s2
    80005066:	777d                	lui	a4,0xfffff
    80005068:	8ff9                	and	a5,a5,a4
    8000506a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000506e:	4691                	li	a3,4
    80005070:	6609                	lui	a2,0x2
    80005072:	963e                	add	a2,a2,a5
    80005074:	85be                	mv	a1,a5
    80005076:	855a                	mv	a0,s6
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	398080e7          	jalr	920(ra) # 80001410 <uvmalloc>
    80005080:	8c2a                	mv	s8,a0
  ip = 0;
    80005082:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005084:	12050e63          	beqz	a0,800051c0 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005088:	75f9                	lui	a1,0xffffe
    8000508a:	95aa                	add	a1,a1,a0
    8000508c:	855a                	mv	a0,s6
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	5ac080e7          	jalr	1452(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80005096:	7afd                	lui	s5,0xfffff
    80005098:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000509a:	df043783          	ld	a5,-528(s0)
    8000509e:	6388                	ld	a0,0(a5)
    800050a0:	c925                	beqz	a0,80005110 <exec+0x224>
    800050a2:	e9040993          	addi	s3,s0,-368
    800050a6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050aa:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050ac:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050ae:	ffffc097          	auipc	ra,0xffffc
    800050b2:	da0080e7          	jalr	-608(ra) # 80000e4e <strlen>
    800050b6:	0015079b          	addiw	a5,a0,1
    800050ba:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050be:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800050c2:	13596663          	bltu	s2,s5,800051ee <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050c6:	df043d83          	ld	s11,-528(s0)
    800050ca:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050ce:	8552                	mv	a0,s4
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	d7e080e7          	jalr	-642(ra) # 80000e4e <strlen>
    800050d8:	0015069b          	addiw	a3,a0,1
    800050dc:	8652                	mv	a2,s4
    800050de:	85ca                	mv	a1,s2
    800050e0:	855a                	mv	a0,s6
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	58a080e7          	jalr	1418(ra) # 8000166c <copyout>
    800050ea:	10054663          	bltz	a0,800051f6 <exec+0x30a>
    ustack[argc] = sp;
    800050ee:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050f2:	0485                	addi	s1,s1,1
    800050f4:	008d8793          	addi	a5,s11,8
    800050f8:	def43823          	sd	a5,-528(s0)
    800050fc:	008db503          	ld	a0,8(s11)
    80005100:	c911                	beqz	a0,80005114 <exec+0x228>
    if(argc >= MAXARG)
    80005102:	09a1                	addi	s3,s3,8
    80005104:	fb3c95e3          	bne	s9,s3,800050ae <exec+0x1c2>
  sz = sz1;
    80005108:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000510c:	4a81                	li	s5,0
    8000510e:	a84d                	j	800051c0 <exec+0x2d4>
  sp = sz;
    80005110:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005112:	4481                	li	s1,0
  ustack[argc] = 0;
    80005114:	00349793          	slli	a5,s1,0x3
    80005118:	f9078793          	addi	a5,a5,-112
    8000511c:	97a2                	add	a5,a5,s0
    8000511e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005122:	00148693          	addi	a3,s1,1
    80005126:	068e                	slli	a3,a3,0x3
    80005128:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000512c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005130:	01597663          	bgeu	s2,s5,8000513c <exec+0x250>
  sz = sz1;
    80005134:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005138:	4a81                	li	s5,0
    8000513a:	a059                	j	800051c0 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000513c:	e9040613          	addi	a2,s0,-368
    80005140:	85ca                	mv	a1,s2
    80005142:	855a                	mv	a0,s6
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	528080e7          	jalr	1320(ra) # 8000166c <copyout>
    8000514c:	0a054963          	bltz	a0,800051fe <exec+0x312>
  p->trapframe->a1 = sp;
    80005150:	058bb783          	ld	a5,88(s7)
    80005154:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005158:	de843783          	ld	a5,-536(s0)
    8000515c:	0007c703          	lbu	a4,0(a5)
    80005160:	cf11                	beqz	a4,8000517c <exec+0x290>
    80005162:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005164:	02f00693          	li	a3,47
    80005168:	a039                	j	80005176 <exec+0x28a>
      last = s+1;
    8000516a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000516e:	0785                	addi	a5,a5,1
    80005170:	fff7c703          	lbu	a4,-1(a5)
    80005174:	c701                	beqz	a4,8000517c <exec+0x290>
    if(*s == '/')
    80005176:	fed71ce3          	bne	a4,a3,8000516e <exec+0x282>
    8000517a:	bfc5                	j	8000516a <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000517c:	4641                	li	a2,16
    8000517e:	de843583          	ld	a1,-536(s0)
    80005182:	158b8513          	addi	a0,s7,344
    80005186:	ffffc097          	auipc	ra,0xffffc
    8000518a:	c96080e7          	jalr	-874(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000518e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005192:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005196:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000519a:	058bb783          	ld	a5,88(s7)
    8000519e:	e6843703          	ld	a4,-408(s0)
    800051a2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051a4:	058bb783          	ld	a5,88(s7)
    800051a8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051ac:	85ea                	mv	a1,s10
    800051ae:	ffffd097          	auipc	ra,0xffffd
    800051b2:	95e080e7          	jalr	-1698(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051b6:	0004851b          	sext.w	a0,s1
    800051ba:	b3f9                	j	80004f88 <exec+0x9c>
    800051bc:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051c0:	df843583          	ld	a1,-520(s0)
    800051c4:	855a                	mv	a0,s6
    800051c6:	ffffd097          	auipc	ra,0xffffd
    800051ca:	946080e7          	jalr	-1722(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800051ce:	da0a93e3          	bnez	s5,80004f74 <exec+0x88>
  return -1;
    800051d2:	557d                	li	a0,-1
    800051d4:	bb55                	j	80004f88 <exec+0x9c>
    800051d6:	df243c23          	sd	s2,-520(s0)
    800051da:	b7dd                	j	800051c0 <exec+0x2d4>
    800051dc:	df243c23          	sd	s2,-520(s0)
    800051e0:	b7c5                	j	800051c0 <exec+0x2d4>
    800051e2:	df243c23          	sd	s2,-520(s0)
    800051e6:	bfe9                	j	800051c0 <exec+0x2d4>
    800051e8:	df243c23          	sd	s2,-520(s0)
    800051ec:	bfd1                	j	800051c0 <exec+0x2d4>
  sz = sz1;
    800051ee:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051f2:	4a81                	li	s5,0
    800051f4:	b7f1                	j	800051c0 <exec+0x2d4>
  sz = sz1;
    800051f6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051fa:	4a81                	li	s5,0
    800051fc:	b7d1                	j	800051c0 <exec+0x2d4>
  sz = sz1;
    800051fe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005202:	4a81                	li	s5,0
    80005204:	bf75                	j	800051c0 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005206:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000520a:	e0843783          	ld	a5,-504(s0)
    8000520e:	0017869b          	addiw	a3,a5,1
    80005212:	e0d43423          	sd	a3,-504(s0)
    80005216:	e0043783          	ld	a5,-512(s0)
    8000521a:	0387879b          	addiw	a5,a5,56
    8000521e:	e8845703          	lhu	a4,-376(s0)
    80005222:	e0e6dfe3          	bge	a3,a4,80005040 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005226:	2781                	sext.w	a5,a5
    80005228:	e0f43023          	sd	a5,-512(s0)
    8000522c:	03800713          	li	a4,56
    80005230:	86be                	mv	a3,a5
    80005232:	e1840613          	addi	a2,s0,-488
    80005236:	4581                	li	a1,0
    80005238:	8556                	mv	a0,s5
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	a58080e7          	jalr	-1448(ra) # 80003c92 <readi>
    80005242:	03800793          	li	a5,56
    80005246:	f6f51be3          	bne	a0,a5,800051bc <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000524a:	e1842783          	lw	a5,-488(s0)
    8000524e:	4705                	li	a4,1
    80005250:	fae79de3          	bne	a5,a4,8000520a <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005254:	e4043483          	ld	s1,-448(s0)
    80005258:	e3843783          	ld	a5,-456(s0)
    8000525c:	f6f4ede3          	bltu	s1,a5,800051d6 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005260:	e2843783          	ld	a5,-472(s0)
    80005264:	94be                	add	s1,s1,a5
    80005266:	f6f4ebe3          	bltu	s1,a5,800051dc <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000526a:	de043703          	ld	a4,-544(s0)
    8000526e:	8ff9                	and	a5,a5,a4
    80005270:	fbad                	bnez	a5,800051e2 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005272:	e1c42503          	lw	a0,-484(s0)
    80005276:	00000097          	auipc	ra,0x0
    8000527a:	c5c080e7          	jalr	-932(ra) # 80004ed2 <flags2perm>
    8000527e:	86aa                	mv	a3,a0
    80005280:	8626                	mv	a2,s1
    80005282:	85ca                	mv	a1,s2
    80005284:	855a                	mv	a0,s6
    80005286:	ffffc097          	auipc	ra,0xffffc
    8000528a:	18a080e7          	jalr	394(ra) # 80001410 <uvmalloc>
    8000528e:	dea43c23          	sd	a0,-520(s0)
    80005292:	d939                	beqz	a0,800051e8 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005294:	e2843c03          	ld	s8,-472(s0)
    80005298:	e2042c83          	lw	s9,-480(s0)
    8000529c:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052a0:	f60b83e3          	beqz	s7,80005206 <exec+0x31a>
    800052a4:	89de                	mv	s3,s7
    800052a6:	4481                	li	s1,0
    800052a8:	bb9d                	j	8000501e <exec+0x132>

00000000800052aa <argfd>:
int readcount = 0;
// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052aa:	7179                	addi	sp,sp,-48
    800052ac:	f406                	sd	ra,40(sp)
    800052ae:	f022                	sd	s0,32(sp)
    800052b0:	ec26                	sd	s1,24(sp)
    800052b2:	e84a                	sd	s2,16(sp)
    800052b4:	1800                	addi	s0,sp,48
    800052b6:	892e                	mv	s2,a1
    800052b8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052ba:	fdc40593          	addi	a1,s0,-36
    800052be:	ffffe097          	auipc	ra,0xffffe
    800052c2:	a62080e7          	jalr	-1438(ra) # 80002d20 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052c6:	fdc42703          	lw	a4,-36(s0)
    800052ca:	47bd                	li	a5,15
    800052cc:	02e7eb63          	bltu	a5,a4,80005302 <argfd+0x58>
    800052d0:	ffffc097          	auipc	ra,0xffffc
    800052d4:	6dc080e7          	jalr	1756(ra) # 800019ac <myproc>
    800052d8:	fdc42703          	lw	a4,-36(s0)
    800052dc:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc48a>
    800052e0:	078e                	slli	a5,a5,0x3
    800052e2:	953e                	add	a0,a0,a5
    800052e4:	611c                	ld	a5,0(a0)
    800052e6:	c385                	beqz	a5,80005306 <argfd+0x5c>
    return -1;
  if(pfd)
    800052e8:	00090463          	beqz	s2,800052f0 <argfd+0x46>
    *pfd = fd;
    800052ec:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052f0:	4501                	li	a0,0
  if(pf)
    800052f2:	c091                	beqz	s1,800052f6 <argfd+0x4c>
    *pf = f;
    800052f4:	e09c                	sd	a5,0(s1)
}
    800052f6:	70a2                	ld	ra,40(sp)
    800052f8:	7402                	ld	s0,32(sp)
    800052fa:	64e2                	ld	s1,24(sp)
    800052fc:	6942                	ld	s2,16(sp)
    800052fe:	6145                	addi	sp,sp,48
    80005300:	8082                	ret
    return -1;
    80005302:	557d                	li	a0,-1
    80005304:	bfcd                	j	800052f6 <argfd+0x4c>
    80005306:	557d                	li	a0,-1
    80005308:	b7fd                	j	800052f6 <argfd+0x4c>

000000008000530a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000530a:	1101                	addi	sp,sp,-32
    8000530c:	ec06                	sd	ra,24(sp)
    8000530e:	e822                	sd	s0,16(sp)
    80005310:	e426                	sd	s1,8(sp)
    80005312:	1000                	addi	s0,sp,32
    80005314:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005316:	ffffc097          	auipc	ra,0xffffc
    8000531a:	696080e7          	jalr	1686(ra) # 800019ac <myproc>
    8000531e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005320:	0d050793          	addi	a5,a0,208
    80005324:	4501                	li	a0,0
    80005326:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005328:	6398                	ld	a4,0(a5)
    8000532a:	cb19                	beqz	a4,80005340 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000532c:	2505                	addiw	a0,a0,1
    8000532e:	07a1                	addi	a5,a5,8
    80005330:	fed51ce3          	bne	a0,a3,80005328 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005334:	557d                	li	a0,-1
}
    80005336:	60e2                	ld	ra,24(sp)
    80005338:	6442                	ld	s0,16(sp)
    8000533a:	64a2                	ld	s1,8(sp)
    8000533c:	6105                	addi	sp,sp,32
    8000533e:	8082                	ret
      p->ofile[fd] = f;
    80005340:	01a50793          	addi	a5,a0,26
    80005344:	078e                	slli	a5,a5,0x3
    80005346:	963e                	add	a2,a2,a5
    80005348:	e204                	sd	s1,0(a2)
      return fd;
    8000534a:	b7f5                	j	80005336 <fdalloc+0x2c>

000000008000534c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000534c:	715d                	addi	sp,sp,-80
    8000534e:	e486                	sd	ra,72(sp)
    80005350:	e0a2                	sd	s0,64(sp)
    80005352:	fc26                	sd	s1,56(sp)
    80005354:	f84a                	sd	s2,48(sp)
    80005356:	f44e                	sd	s3,40(sp)
    80005358:	f052                	sd	s4,32(sp)
    8000535a:	ec56                	sd	s5,24(sp)
    8000535c:	e85a                	sd	s6,16(sp)
    8000535e:	0880                	addi	s0,sp,80
    80005360:	8b2e                	mv	s6,a1
    80005362:	89b2                	mv	s3,a2
    80005364:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005366:	fb040593          	addi	a1,s0,-80
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	e3e080e7          	jalr	-450(ra) # 800041a8 <nameiparent>
    80005372:	84aa                	mv	s1,a0
    80005374:	14050f63          	beqz	a0,800054d2 <create+0x186>
    return 0;

  ilock(dp);
    80005378:	ffffe097          	auipc	ra,0xffffe
    8000537c:	666080e7          	jalr	1638(ra) # 800039de <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005380:	4601                	li	a2,0
    80005382:	fb040593          	addi	a1,s0,-80
    80005386:	8526                	mv	a0,s1
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	b3a080e7          	jalr	-1222(ra) # 80003ec2 <dirlookup>
    80005390:	8aaa                	mv	s5,a0
    80005392:	c931                	beqz	a0,800053e6 <create+0x9a>
    iunlockput(dp);
    80005394:	8526                	mv	a0,s1
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	8aa080e7          	jalr	-1878(ra) # 80003c40 <iunlockput>
    ilock(ip);
    8000539e:	8556                	mv	a0,s5
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	63e080e7          	jalr	1598(ra) # 800039de <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053a8:	000b059b          	sext.w	a1,s6
    800053ac:	4789                	li	a5,2
    800053ae:	02f59563          	bne	a1,a5,800053d8 <create+0x8c>
    800053b2:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc4b4>
    800053b6:	37f9                	addiw	a5,a5,-2
    800053b8:	17c2                	slli	a5,a5,0x30
    800053ba:	93c1                	srli	a5,a5,0x30
    800053bc:	4705                	li	a4,1
    800053be:	00f76d63          	bltu	a4,a5,800053d8 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053c2:	8556                	mv	a0,s5
    800053c4:	60a6                	ld	ra,72(sp)
    800053c6:	6406                	ld	s0,64(sp)
    800053c8:	74e2                	ld	s1,56(sp)
    800053ca:	7942                	ld	s2,48(sp)
    800053cc:	79a2                	ld	s3,40(sp)
    800053ce:	7a02                	ld	s4,32(sp)
    800053d0:	6ae2                	ld	s5,24(sp)
    800053d2:	6b42                	ld	s6,16(sp)
    800053d4:	6161                	addi	sp,sp,80
    800053d6:	8082                	ret
    iunlockput(ip);
    800053d8:	8556                	mv	a0,s5
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	866080e7          	jalr	-1946(ra) # 80003c40 <iunlockput>
    return 0;
    800053e2:	4a81                	li	s5,0
    800053e4:	bff9                	j	800053c2 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053e6:	85da                	mv	a1,s6
    800053e8:	4088                	lw	a0,0(s1)
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	456080e7          	jalr	1110(ra) # 80003840 <ialloc>
    800053f2:	8a2a                	mv	s4,a0
    800053f4:	c539                	beqz	a0,80005442 <create+0xf6>
  ilock(ip);
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	5e8080e7          	jalr	1512(ra) # 800039de <ilock>
  ip->major = major;
    800053fe:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005402:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005406:	4905                	li	s2,1
    80005408:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000540c:	8552                	mv	a0,s4
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	504080e7          	jalr	1284(ra) # 80003912 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005416:	000b059b          	sext.w	a1,s6
    8000541a:	03258b63          	beq	a1,s2,80005450 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000541e:	004a2603          	lw	a2,4(s4)
    80005422:	fb040593          	addi	a1,s0,-80
    80005426:	8526                	mv	a0,s1
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	cb0080e7          	jalr	-848(ra) # 800040d8 <dirlink>
    80005430:	06054f63          	bltz	a0,800054ae <create+0x162>
  iunlockput(dp);
    80005434:	8526                	mv	a0,s1
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	80a080e7          	jalr	-2038(ra) # 80003c40 <iunlockput>
  return ip;
    8000543e:	8ad2                	mv	s5,s4
    80005440:	b749                	j	800053c2 <create+0x76>
    iunlockput(dp);
    80005442:	8526                	mv	a0,s1
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	7fc080e7          	jalr	2044(ra) # 80003c40 <iunlockput>
    return 0;
    8000544c:	8ad2                	mv	s5,s4
    8000544e:	bf95                	j	800053c2 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005450:	004a2603          	lw	a2,4(s4)
    80005454:	00003597          	auipc	a1,0x3
    80005458:	2bc58593          	addi	a1,a1,700 # 80008710 <syscalls+0x2c0>
    8000545c:	8552                	mv	a0,s4
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	c7a080e7          	jalr	-902(ra) # 800040d8 <dirlink>
    80005466:	04054463          	bltz	a0,800054ae <create+0x162>
    8000546a:	40d0                	lw	a2,4(s1)
    8000546c:	00003597          	auipc	a1,0x3
    80005470:	2ac58593          	addi	a1,a1,684 # 80008718 <syscalls+0x2c8>
    80005474:	8552                	mv	a0,s4
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	c62080e7          	jalr	-926(ra) # 800040d8 <dirlink>
    8000547e:	02054863          	bltz	a0,800054ae <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005482:	004a2603          	lw	a2,4(s4)
    80005486:	fb040593          	addi	a1,s0,-80
    8000548a:	8526                	mv	a0,s1
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	c4c080e7          	jalr	-948(ra) # 800040d8 <dirlink>
    80005494:	00054d63          	bltz	a0,800054ae <create+0x162>
    dp->nlink++;  // for ".."
    80005498:	04a4d783          	lhu	a5,74(s1)
    8000549c:	2785                	addiw	a5,a5,1
    8000549e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800054a2:	8526                	mv	a0,s1
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	46e080e7          	jalr	1134(ra) # 80003912 <iupdate>
    800054ac:	b761                	j	80005434 <create+0xe8>
  ip->nlink = 0;
    800054ae:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054b2:	8552                	mv	a0,s4
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	45e080e7          	jalr	1118(ra) # 80003912 <iupdate>
  iunlockput(ip);
    800054bc:	8552                	mv	a0,s4
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	782080e7          	jalr	1922(ra) # 80003c40 <iunlockput>
  iunlockput(dp);
    800054c6:	8526                	mv	a0,s1
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	778080e7          	jalr	1912(ra) # 80003c40 <iunlockput>
  return 0;
    800054d0:	bdcd                	j	800053c2 <create+0x76>
    return 0;
    800054d2:	8aaa                	mv	s5,a0
    800054d4:	b5fd                	j	800053c2 <create+0x76>

00000000800054d6 <sys_dup>:
{
    800054d6:	7179                	addi	sp,sp,-48
    800054d8:	f406                	sd	ra,40(sp)
    800054da:	f022                	sd	s0,32(sp)
    800054dc:	ec26                	sd	s1,24(sp)
    800054de:	e84a                	sd	s2,16(sp)
    800054e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054e2:	fd840613          	addi	a2,s0,-40
    800054e6:	4581                	li	a1,0
    800054e8:	4501                	li	a0,0
    800054ea:	00000097          	auipc	ra,0x0
    800054ee:	dc0080e7          	jalr	-576(ra) # 800052aa <argfd>
    return -1;
    800054f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054f4:	02054363          	bltz	a0,8000551a <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800054f8:	fd843903          	ld	s2,-40(s0)
    800054fc:	854a                	mv	a0,s2
    800054fe:	00000097          	auipc	ra,0x0
    80005502:	e0c080e7          	jalr	-500(ra) # 8000530a <fdalloc>
    80005506:	84aa                	mv	s1,a0
    return -1;
    80005508:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000550a:	00054863          	bltz	a0,8000551a <sys_dup+0x44>
  filedup(f);
    8000550e:	854a                	mv	a0,s2
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	310080e7          	jalr	784(ra) # 80004820 <filedup>
  return fd;
    80005518:	87a6                	mv	a5,s1
}
    8000551a:	853e                	mv	a0,a5
    8000551c:	70a2                	ld	ra,40(sp)
    8000551e:	7402                	ld	s0,32(sp)
    80005520:	64e2                	ld	s1,24(sp)
    80005522:	6942                	ld	s2,16(sp)
    80005524:	6145                	addi	sp,sp,48
    80005526:	8082                	ret

0000000080005528 <sys_read>:
{
    80005528:	7179                	addi	sp,sp,-48
    8000552a:	f406                	sd	ra,40(sp)
    8000552c:	f022                	sd	s0,32(sp)
    8000552e:	1800                	addi	s0,sp,48
  readcount++;
    80005530:	00003717          	auipc	a4,0x3
    80005534:	3e470713          	addi	a4,a4,996 # 80008914 <readcount>
    80005538:	431c                	lw	a5,0(a4)
    8000553a:	2785                	addiw	a5,a5,1
    8000553c:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    8000553e:	fd840593          	addi	a1,s0,-40
    80005542:	4505                	li	a0,1
    80005544:	ffffd097          	auipc	ra,0xffffd
    80005548:	7fc080e7          	jalr	2044(ra) # 80002d40 <argaddr>
  argint(2, &n);
    8000554c:	fe440593          	addi	a1,s0,-28
    80005550:	4509                	li	a0,2
    80005552:	ffffd097          	auipc	ra,0xffffd
    80005556:	7ce080e7          	jalr	1998(ra) # 80002d20 <argint>
  if(argfd(0, 0, &f) < 0)
    8000555a:	fe840613          	addi	a2,s0,-24
    8000555e:	4581                	li	a1,0
    80005560:	4501                	li	a0,0
    80005562:	00000097          	auipc	ra,0x0
    80005566:	d48080e7          	jalr	-696(ra) # 800052aa <argfd>
    8000556a:	87aa                	mv	a5,a0
    return -1;
    8000556c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000556e:	0007cc63          	bltz	a5,80005586 <sys_read+0x5e>
  return fileread(f, p, n);
    80005572:	fe442603          	lw	a2,-28(s0)
    80005576:	fd843583          	ld	a1,-40(s0)
    8000557a:	fe843503          	ld	a0,-24(s0)
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	42e080e7          	jalr	1070(ra) # 800049ac <fileread>
}
    80005586:	70a2                	ld	ra,40(sp)
    80005588:	7402                	ld	s0,32(sp)
    8000558a:	6145                	addi	sp,sp,48
    8000558c:	8082                	ret

000000008000558e <sys_write>:
{
    8000558e:	7179                	addi	sp,sp,-48
    80005590:	f406                	sd	ra,40(sp)
    80005592:	f022                	sd	s0,32(sp)
    80005594:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005596:	fd840593          	addi	a1,s0,-40
    8000559a:	4505                	li	a0,1
    8000559c:	ffffd097          	auipc	ra,0xffffd
    800055a0:	7a4080e7          	jalr	1956(ra) # 80002d40 <argaddr>
  argint(2, &n);
    800055a4:	fe440593          	addi	a1,s0,-28
    800055a8:	4509                	li	a0,2
    800055aa:	ffffd097          	auipc	ra,0xffffd
    800055ae:	776080e7          	jalr	1910(ra) # 80002d20 <argint>
  if(argfd(0, 0, &f) < 0)
    800055b2:	fe840613          	addi	a2,s0,-24
    800055b6:	4581                	li	a1,0
    800055b8:	4501                	li	a0,0
    800055ba:	00000097          	auipc	ra,0x0
    800055be:	cf0080e7          	jalr	-784(ra) # 800052aa <argfd>
    800055c2:	87aa                	mv	a5,a0
    return -1;
    800055c4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055c6:	0007cc63          	bltz	a5,800055de <sys_write+0x50>
  return filewrite(f, p, n);
    800055ca:	fe442603          	lw	a2,-28(s0)
    800055ce:	fd843583          	ld	a1,-40(s0)
    800055d2:	fe843503          	ld	a0,-24(s0)
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	498080e7          	jalr	1176(ra) # 80004a6e <filewrite>
}
    800055de:	70a2                	ld	ra,40(sp)
    800055e0:	7402                	ld	s0,32(sp)
    800055e2:	6145                	addi	sp,sp,48
    800055e4:	8082                	ret

00000000800055e6 <sys_close>:
{
    800055e6:	1101                	addi	sp,sp,-32
    800055e8:	ec06                	sd	ra,24(sp)
    800055ea:	e822                	sd	s0,16(sp)
    800055ec:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055ee:	fe040613          	addi	a2,s0,-32
    800055f2:	fec40593          	addi	a1,s0,-20
    800055f6:	4501                	li	a0,0
    800055f8:	00000097          	auipc	ra,0x0
    800055fc:	cb2080e7          	jalr	-846(ra) # 800052aa <argfd>
    return -1;
    80005600:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005602:	02054463          	bltz	a0,8000562a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005606:	ffffc097          	auipc	ra,0xffffc
    8000560a:	3a6080e7          	jalr	934(ra) # 800019ac <myproc>
    8000560e:	fec42783          	lw	a5,-20(s0)
    80005612:	07e9                	addi	a5,a5,26
    80005614:	078e                	slli	a5,a5,0x3
    80005616:	953e                	add	a0,a0,a5
    80005618:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000561c:	fe043503          	ld	a0,-32(s0)
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	252080e7          	jalr	594(ra) # 80004872 <fileclose>
  return 0;
    80005628:	4781                	li	a5,0
}
    8000562a:	853e                	mv	a0,a5
    8000562c:	60e2                	ld	ra,24(sp)
    8000562e:	6442                	ld	s0,16(sp)
    80005630:	6105                	addi	sp,sp,32
    80005632:	8082                	ret

0000000080005634 <sys_fstat>:
{
    80005634:	1101                	addi	sp,sp,-32
    80005636:	ec06                	sd	ra,24(sp)
    80005638:	e822                	sd	s0,16(sp)
    8000563a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000563c:	fe040593          	addi	a1,s0,-32
    80005640:	4505                	li	a0,1
    80005642:	ffffd097          	auipc	ra,0xffffd
    80005646:	6fe080e7          	jalr	1790(ra) # 80002d40 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000564a:	fe840613          	addi	a2,s0,-24
    8000564e:	4581                	li	a1,0
    80005650:	4501                	li	a0,0
    80005652:	00000097          	auipc	ra,0x0
    80005656:	c58080e7          	jalr	-936(ra) # 800052aa <argfd>
    8000565a:	87aa                	mv	a5,a0
    return -1;
    8000565c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000565e:	0007ca63          	bltz	a5,80005672 <sys_fstat+0x3e>
  return filestat(f, st);
    80005662:	fe043583          	ld	a1,-32(s0)
    80005666:	fe843503          	ld	a0,-24(s0)
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	2d0080e7          	jalr	720(ra) # 8000493a <filestat>
}
    80005672:	60e2                	ld	ra,24(sp)
    80005674:	6442                	ld	s0,16(sp)
    80005676:	6105                	addi	sp,sp,32
    80005678:	8082                	ret

000000008000567a <sys_link>:
{
    8000567a:	7169                	addi	sp,sp,-304
    8000567c:	f606                	sd	ra,296(sp)
    8000567e:	f222                	sd	s0,288(sp)
    80005680:	ee26                	sd	s1,280(sp)
    80005682:	ea4a                	sd	s2,272(sp)
    80005684:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005686:	08000613          	li	a2,128
    8000568a:	ed040593          	addi	a1,s0,-304
    8000568e:	4501                	li	a0,0
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	6d0080e7          	jalr	1744(ra) # 80002d60 <argstr>
    return -1;
    80005698:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000569a:	10054e63          	bltz	a0,800057b6 <sys_link+0x13c>
    8000569e:	08000613          	li	a2,128
    800056a2:	f5040593          	addi	a1,s0,-176
    800056a6:	4505                	li	a0,1
    800056a8:	ffffd097          	auipc	ra,0xffffd
    800056ac:	6b8080e7          	jalr	1720(ra) # 80002d60 <argstr>
    return -1;
    800056b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056b2:	10054263          	bltz	a0,800057b6 <sys_link+0x13c>
  begin_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	cf4080e7          	jalr	-780(ra) # 800043aa <begin_op>
  if((ip = namei(old)) == 0){
    800056be:	ed040513          	addi	a0,s0,-304
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	ac8080e7          	jalr	-1336(ra) # 8000418a <namei>
    800056ca:	84aa                	mv	s1,a0
    800056cc:	c551                	beqz	a0,80005758 <sys_link+0xde>
  ilock(ip);
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	310080e7          	jalr	784(ra) # 800039de <ilock>
  if(ip->type == T_DIR){
    800056d6:	04449703          	lh	a4,68(s1)
    800056da:	4785                	li	a5,1
    800056dc:	08f70463          	beq	a4,a5,80005764 <sys_link+0xea>
  ip->nlink++;
    800056e0:	04a4d783          	lhu	a5,74(s1)
    800056e4:	2785                	addiw	a5,a5,1
    800056e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	226080e7          	jalr	550(ra) # 80003912 <iupdate>
  iunlock(ip);
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	3aa080e7          	jalr	938(ra) # 80003aa0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056fe:	fd040593          	addi	a1,s0,-48
    80005702:	f5040513          	addi	a0,s0,-176
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	aa2080e7          	jalr	-1374(ra) # 800041a8 <nameiparent>
    8000570e:	892a                	mv	s2,a0
    80005710:	c935                	beqz	a0,80005784 <sys_link+0x10a>
  ilock(dp);
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	2cc080e7          	jalr	716(ra) # 800039de <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000571a:	00092703          	lw	a4,0(s2)
    8000571e:	409c                	lw	a5,0(s1)
    80005720:	04f71d63          	bne	a4,a5,8000577a <sys_link+0x100>
    80005724:	40d0                	lw	a2,4(s1)
    80005726:	fd040593          	addi	a1,s0,-48
    8000572a:	854a                	mv	a0,s2
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	9ac080e7          	jalr	-1620(ra) # 800040d8 <dirlink>
    80005734:	04054363          	bltz	a0,8000577a <sys_link+0x100>
  iunlockput(dp);
    80005738:	854a                	mv	a0,s2
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	506080e7          	jalr	1286(ra) # 80003c40 <iunlockput>
  iput(ip);
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	454080e7          	jalr	1108(ra) # 80003b98 <iput>
  end_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	cdc080e7          	jalr	-804(ra) # 80004428 <end_op>
  return 0;
    80005754:	4781                	li	a5,0
    80005756:	a085                	j	800057b6 <sys_link+0x13c>
    end_op();
    80005758:	fffff097          	auipc	ra,0xfffff
    8000575c:	cd0080e7          	jalr	-816(ra) # 80004428 <end_op>
    return -1;
    80005760:	57fd                	li	a5,-1
    80005762:	a891                	j	800057b6 <sys_link+0x13c>
    iunlockput(ip);
    80005764:	8526                	mv	a0,s1
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	4da080e7          	jalr	1242(ra) # 80003c40 <iunlockput>
    end_op();
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	cba080e7          	jalr	-838(ra) # 80004428 <end_op>
    return -1;
    80005776:	57fd                	li	a5,-1
    80005778:	a83d                	j	800057b6 <sys_link+0x13c>
    iunlockput(dp);
    8000577a:	854a                	mv	a0,s2
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	4c4080e7          	jalr	1220(ra) # 80003c40 <iunlockput>
  ilock(ip);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	258080e7          	jalr	600(ra) # 800039de <ilock>
  ip->nlink--;
    8000578e:	04a4d783          	lhu	a5,74(s1)
    80005792:	37fd                	addiw	a5,a5,-1
    80005794:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005798:	8526                	mv	a0,s1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	178080e7          	jalr	376(ra) # 80003912 <iupdate>
  iunlockput(ip);
    800057a2:	8526                	mv	a0,s1
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	49c080e7          	jalr	1180(ra) # 80003c40 <iunlockput>
  end_op();
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	c7c080e7          	jalr	-900(ra) # 80004428 <end_op>
  return -1;
    800057b4:	57fd                	li	a5,-1
}
    800057b6:	853e                	mv	a0,a5
    800057b8:	70b2                	ld	ra,296(sp)
    800057ba:	7412                	ld	s0,288(sp)
    800057bc:	64f2                	ld	s1,280(sp)
    800057be:	6952                	ld	s2,272(sp)
    800057c0:	6155                	addi	sp,sp,304
    800057c2:	8082                	ret

00000000800057c4 <sys_unlink>:
{
    800057c4:	7151                	addi	sp,sp,-240
    800057c6:	f586                	sd	ra,232(sp)
    800057c8:	f1a2                	sd	s0,224(sp)
    800057ca:	eda6                	sd	s1,216(sp)
    800057cc:	e9ca                	sd	s2,208(sp)
    800057ce:	e5ce                	sd	s3,200(sp)
    800057d0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057d2:	08000613          	li	a2,128
    800057d6:	f3040593          	addi	a1,s0,-208
    800057da:	4501                	li	a0,0
    800057dc:	ffffd097          	auipc	ra,0xffffd
    800057e0:	584080e7          	jalr	1412(ra) # 80002d60 <argstr>
    800057e4:	18054163          	bltz	a0,80005966 <sys_unlink+0x1a2>
  begin_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	bc2080e7          	jalr	-1086(ra) # 800043aa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057f0:	fb040593          	addi	a1,s0,-80
    800057f4:	f3040513          	addi	a0,s0,-208
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	9b0080e7          	jalr	-1616(ra) # 800041a8 <nameiparent>
    80005800:	84aa                	mv	s1,a0
    80005802:	c979                	beqz	a0,800058d8 <sys_unlink+0x114>
  ilock(dp);
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	1da080e7          	jalr	474(ra) # 800039de <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000580c:	00003597          	auipc	a1,0x3
    80005810:	f0458593          	addi	a1,a1,-252 # 80008710 <syscalls+0x2c0>
    80005814:	fb040513          	addi	a0,s0,-80
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	690080e7          	jalr	1680(ra) # 80003ea8 <namecmp>
    80005820:	14050a63          	beqz	a0,80005974 <sys_unlink+0x1b0>
    80005824:	00003597          	auipc	a1,0x3
    80005828:	ef458593          	addi	a1,a1,-268 # 80008718 <syscalls+0x2c8>
    8000582c:	fb040513          	addi	a0,s0,-80
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	678080e7          	jalr	1656(ra) # 80003ea8 <namecmp>
    80005838:	12050e63          	beqz	a0,80005974 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000583c:	f2c40613          	addi	a2,s0,-212
    80005840:	fb040593          	addi	a1,s0,-80
    80005844:	8526                	mv	a0,s1
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	67c080e7          	jalr	1660(ra) # 80003ec2 <dirlookup>
    8000584e:	892a                	mv	s2,a0
    80005850:	12050263          	beqz	a0,80005974 <sys_unlink+0x1b0>
  ilock(ip);
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	18a080e7          	jalr	394(ra) # 800039de <ilock>
  if(ip->nlink < 1)
    8000585c:	04a91783          	lh	a5,74(s2)
    80005860:	08f05263          	blez	a5,800058e4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005864:	04491703          	lh	a4,68(s2)
    80005868:	4785                	li	a5,1
    8000586a:	08f70563          	beq	a4,a5,800058f4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000586e:	4641                	li	a2,16
    80005870:	4581                	li	a1,0
    80005872:	fc040513          	addi	a0,s0,-64
    80005876:	ffffb097          	auipc	ra,0xffffb
    8000587a:	45c080e7          	jalr	1116(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000587e:	4741                	li	a4,16
    80005880:	f2c42683          	lw	a3,-212(s0)
    80005884:	fc040613          	addi	a2,s0,-64
    80005888:	4581                	li	a1,0
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	4fe080e7          	jalr	1278(ra) # 80003d8a <writei>
    80005894:	47c1                	li	a5,16
    80005896:	0af51563          	bne	a0,a5,80005940 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000589a:	04491703          	lh	a4,68(s2)
    8000589e:	4785                	li	a5,1
    800058a0:	0af70863          	beq	a4,a5,80005950 <sys_unlink+0x18c>
  iunlockput(dp);
    800058a4:	8526                	mv	a0,s1
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	39a080e7          	jalr	922(ra) # 80003c40 <iunlockput>
  ip->nlink--;
    800058ae:	04a95783          	lhu	a5,74(s2)
    800058b2:	37fd                	addiw	a5,a5,-1
    800058b4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058b8:	854a                	mv	a0,s2
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	058080e7          	jalr	88(ra) # 80003912 <iupdate>
  iunlockput(ip);
    800058c2:	854a                	mv	a0,s2
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	37c080e7          	jalr	892(ra) # 80003c40 <iunlockput>
  end_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	b5c080e7          	jalr	-1188(ra) # 80004428 <end_op>
  return 0;
    800058d4:	4501                	li	a0,0
    800058d6:	a84d                	j	80005988 <sys_unlink+0x1c4>
    end_op();
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	b50080e7          	jalr	-1200(ra) # 80004428 <end_op>
    return -1;
    800058e0:	557d                	li	a0,-1
    800058e2:	a05d                	j	80005988 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058e4:	00003517          	auipc	a0,0x3
    800058e8:	e3c50513          	addi	a0,a0,-452 # 80008720 <syscalls+0x2d0>
    800058ec:	ffffb097          	auipc	ra,0xffffb
    800058f0:	c54080e7          	jalr	-940(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058f4:	04c92703          	lw	a4,76(s2)
    800058f8:	02000793          	li	a5,32
    800058fc:	f6e7f9e3          	bgeu	a5,a4,8000586e <sys_unlink+0xaa>
    80005900:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005904:	4741                	li	a4,16
    80005906:	86ce                	mv	a3,s3
    80005908:	f1840613          	addi	a2,s0,-232
    8000590c:	4581                	li	a1,0
    8000590e:	854a                	mv	a0,s2
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	382080e7          	jalr	898(ra) # 80003c92 <readi>
    80005918:	47c1                	li	a5,16
    8000591a:	00f51b63          	bne	a0,a5,80005930 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000591e:	f1845783          	lhu	a5,-232(s0)
    80005922:	e7a1                	bnez	a5,8000596a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005924:	29c1                	addiw	s3,s3,16
    80005926:	04c92783          	lw	a5,76(s2)
    8000592a:	fcf9ede3          	bltu	s3,a5,80005904 <sys_unlink+0x140>
    8000592e:	b781                	j	8000586e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005930:	00003517          	auipc	a0,0x3
    80005934:	e0850513          	addi	a0,a0,-504 # 80008738 <syscalls+0x2e8>
    80005938:	ffffb097          	auipc	ra,0xffffb
    8000593c:	c08080e7          	jalr	-1016(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005940:	00003517          	auipc	a0,0x3
    80005944:	e1050513          	addi	a0,a0,-496 # 80008750 <syscalls+0x300>
    80005948:	ffffb097          	auipc	ra,0xffffb
    8000594c:	bf8080e7          	jalr	-1032(ra) # 80000540 <panic>
    dp->nlink--;
    80005950:	04a4d783          	lhu	a5,74(s1)
    80005954:	37fd                	addiw	a5,a5,-1
    80005956:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000595a:	8526                	mv	a0,s1
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	fb6080e7          	jalr	-74(ra) # 80003912 <iupdate>
    80005964:	b781                	j	800058a4 <sys_unlink+0xe0>
    return -1;
    80005966:	557d                	li	a0,-1
    80005968:	a005                	j	80005988 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000596a:	854a                	mv	a0,s2
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	2d4080e7          	jalr	724(ra) # 80003c40 <iunlockput>
  iunlockput(dp);
    80005974:	8526                	mv	a0,s1
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	2ca080e7          	jalr	714(ra) # 80003c40 <iunlockput>
  end_op();
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	aaa080e7          	jalr	-1366(ra) # 80004428 <end_op>
  return -1;
    80005986:	557d                	li	a0,-1
}
    80005988:	70ae                	ld	ra,232(sp)
    8000598a:	740e                	ld	s0,224(sp)
    8000598c:	64ee                	ld	s1,216(sp)
    8000598e:	694e                	ld	s2,208(sp)
    80005990:	69ae                	ld	s3,200(sp)
    80005992:	616d                	addi	sp,sp,240
    80005994:	8082                	ret

0000000080005996 <sys_open>:

uint64
sys_open(void)
{
    80005996:	7131                	addi	sp,sp,-192
    80005998:	fd06                	sd	ra,184(sp)
    8000599a:	f922                	sd	s0,176(sp)
    8000599c:	f526                	sd	s1,168(sp)
    8000599e:	f14a                	sd	s2,160(sp)
    800059a0:	ed4e                	sd	s3,152(sp)
    800059a2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059a4:	f4c40593          	addi	a1,s0,-180
    800059a8:	4505                	li	a0,1
    800059aa:	ffffd097          	auipc	ra,0xffffd
    800059ae:	376080e7          	jalr	886(ra) # 80002d20 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059b2:	08000613          	li	a2,128
    800059b6:	f5040593          	addi	a1,s0,-176
    800059ba:	4501                	li	a0,0
    800059bc:	ffffd097          	auipc	ra,0xffffd
    800059c0:	3a4080e7          	jalr	932(ra) # 80002d60 <argstr>
    800059c4:	87aa                	mv	a5,a0
    return -1;
    800059c6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059c8:	0a07c963          	bltz	a5,80005a7a <sys_open+0xe4>

  begin_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	9de080e7          	jalr	-1570(ra) # 800043aa <begin_op>

  if(omode & O_CREATE){
    800059d4:	f4c42783          	lw	a5,-180(s0)
    800059d8:	2007f793          	andi	a5,a5,512
    800059dc:	cfc5                	beqz	a5,80005a94 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059de:	4681                	li	a3,0
    800059e0:	4601                	li	a2,0
    800059e2:	4589                	li	a1,2
    800059e4:	f5040513          	addi	a0,s0,-176
    800059e8:	00000097          	auipc	ra,0x0
    800059ec:	964080e7          	jalr	-1692(ra) # 8000534c <create>
    800059f0:	84aa                	mv	s1,a0
    if(ip == 0){
    800059f2:	c959                	beqz	a0,80005a88 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059f4:	04449703          	lh	a4,68(s1)
    800059f8:	478d                	li	a5,3
    800059fa:	00f71763          	bne	a4,a5,80005a08 <sys_open+0x72>
    800059fe:	0464d703          	lhu	a4,70(s1)
    80005a02:	47a5                	li	a5,9
    80005a04:	0ce7ed63          	bltu	a5,a4,80005ade <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	dae080e7          	jalr	-594(ra) # 800047b6 <filealloc>
    80005a10:	89aa                	mv	s3,a0
    80005a12:	10050363          	beqz	a0,80005b18 <sys_open+0x182>
    80005a16:	00000097          	auipc	ra,0x0
    80005a1a:	8f4080e7          	jalr	-1804(ra) # 8000530a <fdalloc>
    80005a1e:	892a                	mv	s2,a0
    80005a20:	0e054763          	bltz	a0,80005b0e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a24:	04449703          	lh	a4,68(s1)
    80005a28:	478d                	li	a5,3
    80005a2a:	0cf70563          	beq	a4,a5,80005af4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a2e:	4789                	li	a5,2
    80005a30:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a34:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a38:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a3c:	f4c42783          	lw	a5,-180(s0)
    80005a40:	0017c713          	xori	a4,a5,1
    80005a44:	8b05                	andi	a4,a4,1
    80005a46:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a4a:	0037f713          	andi	a4,a5,3
    80005a4e:	00e03733          	snez	a4,a4
    80005a52:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a56:	4007f793          	andi	a5,a5,1024
    80005a5a:	c791                	beqz	a5,80005a66 <sys_open+0xd0>
    80005a5c:	04449703          	lh	a4,68(s1)
    80005a60:	4789                	li	a5,2
    80005a62:	0af70063          	beq	a4,a5,80005b02 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a66:	8526                	mv	a0,s1
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	038080e7          	jalr	56(ra) # 80003aa0 <iunlock>
  end_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	9b8080e7          	jalr	-1608(ra) # 80004428 <end_op>

  return fd;
    80005a78:	854a                	mv	a0,s2
}
    80005a7a:	70ea                	ld	ra,184(sp)
    80005a7c:	744a                	ld	s0,176(sp)
    80005a7e:	74aa                	ld	s1,168(sp)
    80005a80:	790a                	ld	s2,160(sp)
    80005a82:	69ea                	ld	s3,152(sp)
    80005a84:	6129                	addi	sp,sp,192
    80005a86:	8082                	ret
      end_op();
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	9a0080e7          	jalr	-1632(ra) # 80004428 <end_op>
      return -1;
    80005a90:	557d                	li	a0,-1
    80005a92:	b7e5                	j	80005a7a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a94:	f5040513          	addi	a0,s0,-176
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	6f2080e7          	jalr	1778(ra) # 8000418a <namei>
    80005aa0:	84aa                	mv	s1,a0
    80005aa2:	c905                	beqz	a0,80005ad2 <sys_open+0x13c>
    ilock(ip);
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	f3a080e7          	jalr	-198(ra) # 800039de <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005aac:	04449703          	lh	a4,68(s1)
    80005ab0:	4785                	li	a5,1
    80005ab2:	f4f711e3          	bne	a4,a5,800059f4 <sys_open+0x5e>
    80005ab6:	f4c42783          	lw	a5,-180(s0)
    80005aba:	d7b9                	beqz	a5,80005a08 <sys_open+0x72>
      iunlockput(ip);
    80005abc:	8526                	mv	a0,s1
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	182080e7          	jalr	386(ra) # 80003c40 <iunlockput>
      end_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	962080e7          	jalr	-1694(ra) # 80004428 <end_op>
      return -1;
    80005ace:	557d                	li	a0,-1
    80005ad0:	b76d                	j	80005a7a <sys_open+0xe4>
      end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	956080e7          	jalr	-1706(ra) # 80004428 <end_op>
      return -1;
    80005ada:	557d                	li	a0,-1
    80005adc:	bf79                	j	80005a7a <sys_open+0xe4>
    iunlockput(ip);
    80005ade:	8526                	mv	a0,s1
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	160080e7          	jalr	352(ra) # 80003c40 <iunlockput>
    end_op();
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	940080e7          	jalr	-1728(ra) # 80004428 <end_op>
    return -1;
    80005af0:	557d                	li	a0,-1
    80005af2:	b761                	j	80005a7a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005af4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005af8:	04649783          	lh	a5,70(s1)
    80005afc:	02f99223          	sh	a5,36(s3)
    80005b00:	bf25                	j	80005a38 <sys_open+0xa2>
    itrunc(ip);
    80005b02:	8526                	mv	a0,s1
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	fe8080e7          	jalr	-24(ra) # 80003aec <itrunc>
    80005b0c:	bfa9                	j	80005a66 <sys_open+0xd0>
      fileclose(f);
    80005b0e:	854e                	mv	a0,s3
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	d62080e7          	jalr	-670(ra) # 80004872 <fileclose>
    iunlockput(ip);
    80005b18:	8526                	mv	a0,s1
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	126080e7          	jalr	294(ra) # 80003c40 <iunlockput>
    end_op();
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	906080e7          	jalr	-1786(ra) # 80004428 <end_op>
    return -1;
    80005b2a:	557d                	li	a0,-1
    80005b2c:	b7b9                	j	80005a7a <sys_open+0xe4>

0000000080005b2e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b2e:	7175                	addi	sp,sp,-144
    80005b30:	e506                	sd	ra,136(sp)
    80005b32:	e122                	sd	s0,128(sp)
    80005b34:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	874080e7          	jalr	-1932(ra) # 800043aa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b3e:	08000613          	li	a2,128
    80005b42:	f7040593          	addi	a1,s0,-144
    80005b46:	4501                	li	a0,0
    80005b48:	ffffd097          	auipc	ra,0xffffd
    80005b4c:	218080e7          	jalr	536(ra) # 80002d60 <argstr>
    80005b50:	02054963          	bltz	a0,80005b82 <sys_mkdir+0x54>
    80005b54:	4681                	li	a3,0
    80005b56:	4601                	li	a2,0
    80005b58:	4585                	li	a1,1
    80005b5a:	f7040513          	addi	a0,s0,-144
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	7ee080e7          	jalr	2030(ra) # 8000534c <create>
    80005b66:	cd11                	beqz	a0,80005b82 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	0d8080e7          	jalr	216(ra) # 80003c40 <iunlockput>
  end_op();
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	8b8080e7          	jalr	-1864(ra) # 80004428 <end_op>
  return 0;
    80005b78:	4501                	li	a0,0
}
    80005b7a:	60aa                	ld	ra,136(sp)
    80005b7c:	640a                	ld	s0,128(sp)
    80005b7e:	6149                	addi	sp,sp,144
    80005b80:	8082                	ret
    end_op();
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	8a6080e7          	jalr	-1882(ra) # 80004428 <end_op>
    return -1;
    80005b8a:	557d                	li	a0,-1
    80005b8c:	b7fd                	j	80005b7a <sys_mkdir+0x4c>

0000000080005b8e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b8e:	7135                	addi	sp,sp,-160
    80005b90:	ed06                	sd	ra,152(sp)
    80005b92:	e922                	sd	s0,144(sp)
    80005b94:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	814080e7          	jalr	-2028(ra) # 800043aa <begin_op>
  argint(1, &major);
    80005b9e:	f6c40593          	addi	a1,s0,-148
    80005ba2:	4505                	li	a0,1
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	17c080e7          	jalr	380(ra) # 80002d20 <argint>
  argint(2, &minor);
    80005bac:	f6840593          	addi	a1,s0,-152
    80005bb0:	4509                	li	a0,2
    80005bb2:	ffffd097          	auipc	ra,0xffffd
    80005bb6:	16e080e7          	jalr	366(ra) # 80002d20 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bba:	08000613          	li	a2,128
    80005bbe:	f7040593          	addi	a1,s0,-144
    80005bc2:	4501                	li	a0,0
    80005bc4:	ffffd097          	auipc	ra,0xffffd
    80005bc8:	19c080e7          	jalr	412(ra) # 80002d60 <argstr>
    80005bcc:	02054b63          	bltz	a0,80005c02 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bd0:	f6841683          	lh	a3,-152(s0)
    80005bd4:	f6c41603          	lh	a2,-148(s0)
    80005bd8:	458d                	li	a1,3
    80005bda:	f7040513          	addi	a0,s0,-144
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	76e080e7          	jalr	1902(ra) # 8000534c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005be6:	cd11                	beqz	a0,80005c02 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	058080e7          	jalr	88(ra) # 80003c40 <iunlockput>
  end_op();
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	838080e7          	jalr	-1992(ra) # 80004428 <end_op>
  return 0;
    80005bf8:	4501                	li	a0,0
}
    80005bfa:	60ea                	ld	ra,152(sp)
    80005bfc:	644a                	ld	s0,144(sp)
    80005bfe:	610d                	addi	sp,sp,160
    80005c00:	8082                	ret
    end_op();
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	826080e7          	jalr	-2010(ra) # 80004428 <end_op>
    return -1;
    80005c0a:	557d                	li	a0,-1
    80005c0c:	b7fd                	j	80005bfa <sys_mknod+0x6c>

0000000080005c0e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c0e:	7135                	addi	sp,sp,-160
    80005c10:	ed06                	sd	ra,152(sp)
    80005c12:	e922                	sd	s0,144(sp)
    80005c14:	e526                	sd	s1,136(sp)
    80005c16:	e14a                	sd	s2,128(sp)
    80005c18:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c1a:	ffffc097          	auipc	ra,0xffffc
    80005c1e:	d92080e7          	jalr	-622(ra) # 800019ac <myproc>
    80005c22:	892a                	mv	s2,a0
  
  begin_op();
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	786080e7          	jalr	1926(ra) # 800043aa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c2c:	08000613          	li	a2,128
    80005c30:	f6040593          	addi	a1,s0,-160
    80005c34:	4501                	li	a0,0
    80005c36:	ffffd097          	auipc	ra,0xffffd
    80005c3a:	12a080e7          	jalr	298(ra) # 80002d60 <argstr>
    80005c3e:	04054b63          	bltz	a0,80005c94 <sys_chdir+0x86>
    80005c42:	f6040513          	addi	a0,s0,-160
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	544080e7          	jalr	1348(ra) # 8000418a <namei>
    80005c4e:	84aa                	mv	s1,a0
    80005c50:	c131                	beqz	a0,80005c94 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	d8c080e7          	jalr	-628(ra) # 800039de <ilock>
  if(ip->type != T_DIR){
    80005c5a:	04449703          	lh	a4,68(s1)
    80005c5e:	4785                	li	a5,1
    80005c60:	04f71063          	bne	a4,a5,80005ca0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c64:	8526                	mv	a0,s1
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	e3a080e7          	jalr	-454(ra) # 80003aa0 <iunlock>
  iput(p->cwd);
    80005c6e:	15093503          	ld	a0,336(s2)
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	f26080e7          	jalr	-218(ra) # 80003b98 <iput>
  end_op();
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	7ae080e7          	jalr	1966(ra) # 80004428 <end_op>
  p->cwd = ip;
    80005c82:	14993823          	sd	s1,336(s2)
  return 0;
    80005c86:	4501                	li	a0,0
}
    80005c88:	60ea                	ld	ra,152(sp)
    80005c8a:	644a                	ld	s0,144(sp)
    80005c8c:	64aa                	ld	s1,136(sp)
    80005c8e:	690a                	ld	s2,128(sp)
    80005c90:	610d                	addi	sp,sp,160
    80005c92:	8082                	ret
    end_op();
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	794080e7          	jalr	1940(ra) # 80004428 <end_op>
    return -1;
    80005c9c:	557d                	li	a0,-1
    80005c9e:	b7ed                	j	80005c88 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ca0:	8526                	mv	a0,s1
    80005ca2:	ffffe097          	auipc	ra,0xffffe
    80005ca6:	f9e080e7          	jalr	-98(ra) # 80003c40 <iunlockput>
    end_op();
    80005caa:	ffffe097          	auipc	ra,0xffffe
    80005cae:	77e080e7          	jalr	1918(ra) # 80004428 <end_op>
    return -1;
    80005cb2:	557d                	li	a0,-1
    80005cb4:	bfd1                	j	80005c88 <sys_chdir+0x7a>

0000000080005cb6 <sys_exec>:

uint64
sys_exec(void)
{
    80005cb6:	7145                	addi	sp,sp,-464
    80005cb8:	e786                	sd	ra,456(sp)
    80005cba:	e3a2                	sd	s0,448(sp)
    80005cbc:	ff26                	sd	s1,440(sp)
    80005cbe:	fb4a                	sd	s2,432(sp)
    80005cc0:	f74e                	sd	s3,424(sp)
    80005cc2:	f352                	sd	s4,416(sp)
    80005cc4:	ef56                	sd	s5,408(sp)
    80005cc6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cc8:	e3840593          	addi	a1,s0,-456
    80005ccc:	4505                	li	a0,1
    80005cce:	ffffd097          	auipc	ra,0xffffd
    80005cd2:	072080e7          	jalr	114(ra) # 80002d40 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005cd6:	08000613          	li	a2,128
    80005cda:	f4040593          	addi	a1,s0,-192
    80005cde:	4501                	li	a0,0
    80005ce0:	ffffd097          	auipc	ra,0xffffd
    80005ce4:	080080e7          	jalr	128(ra) # 80002d60 <argstr>
    80005ce8:	87aa                	mv	a5,a0
    return -1;
    80005cea:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cec:	0c07c363          	bltz	a5,80005db2 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005cf0:	10000613          	li	a2,256
    80005cf4:	4581                	li	a1,0
    80005cf6:	e4040513          	addi	a0,s0,-448
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	fd8080e7          	jalr	-40(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d02:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d06:	89a6                	mv	s3,s1
    80005d08:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d0a:	02000a13          	li	s4,32
    80005d0e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d12:	00391513          	slli	a0,s2,0x3
    80005d16:	e3040593          	addi	a1,s0,-464
    80005d1a:	e3843783          	ld	a5,-456(s0)
    80005d1e:	953e                	add	a0,a0,a5
    80005d20:	ffffd097          	auipc	ra,0xffffd
    80005d24:	f62080e7          	jalr	-158(ra) # 80002c82 <fetchaddr>
    80005d28:	02054a63          	bltz	a0,80005d5c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d2c:	e3043783          	ld	a5,-464(s0)
    80005d30:	c3b9                	beqz	a5,80005d76 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d32:	ffffb097          	auipc	ra,0xffffb
    80005d36:	db4080e7          	jalr	-588(ra) # 80000ae6 <kalloc>
    80005d3a:	85aa                	mv	a1,a0
    80005d3c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d40:	cd11                	beqz	a0,80005d5c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d42:	6605                	lui	a2,0x1
    80005d44:	e3043503          	ld	a0,-464(s0)
    80005d48:	ffffd097          	auipc	ra,0xffffd
    80005d4c:	f8c080e7          	jalr	-116(ra) # 80002cd4 <fetchstr>
    80005d50:	00054663          	bltz	a0,80005d5c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d54:	0905                	addi	s2,s2,1
    80005d56:	09a1                	addi	s3,s3,8
    80005d58:	fb491be3          	bne	s2,s4,80005d0e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d5c:	f4040913          	addi	s2,s0,-192
    80005d60:	6088                	ld	a0,0(s1)
    80005d62:	c539                	beqz	a0,80005db0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d64:	ffffb097          	auipc	ra,0xffffb
    80005d68:	c84080e7          	jalr	-892(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d6c:	04a1                	addi	s1,s1,8
    80005d6e:	ff2499e3          	bne	s1,s2,80005d60 <sys_exec+0xaa>
  return -1;
    80005d72:	557d                	li	a0,-1
    80005d74:	a83d                	j	80005db2 <sys_exec+0xfc>
      argv[i] = 0;
    80005d76:	0a8e                	slli	s5,s5,0x3
    80005d78:	fc0a8793          	addi	a5,s5,-64
    80005d7c:	00878ab3          	add	s5,a5,s0
    80005d80:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d84:	e4040593          	addi	a1,s0,-448
    80005d88:	f4040513          	addi	a0,s0,-192
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	160080e7          	jalr	352(ra) # 80004eec <exec>
    80005d94:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d96:	f4040993          	addi	s3,s0,-192
    80005d9a:	6088                	ld	a0,0(s1)
    80005d9c:	c901                	beqz	a0,80005dac <sys_exec+0xf6>
    kfree(argv[i]);
    80005d9e:	ffffb097          	auipc	ra,0xffffb
    80005da2:	c4a080e7          	jalr	-950(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005da6:	04a1                	addi	s1,s1,8
    80005da8:	ff3499e3          	bne	s1,s3,80005d9a <sys_exec+0xe4>
  return ret;
    80005dac:	854a                	mv	a0,s2
    80005dae:	a011                	j	80005db2 <sys_exec+0xfc>
  return -1;
    80005db0:	557d                	li	a0,-1
}
    80005db2:	60be                	ld	ra,456(sp)
    80005db4:	641e                	ld	s0,448(sp)
    80005db6:	74fa                	ld	s1,440(sp)
    80005db8:	795a                	ld	s2,432(sp)
    80005dba:	79ba                	ld	s3,424(sp)
    80005dbc:	7a1a                	ld	s4,416(sp)
    80005dbe:	6afa                	ld	s5,408(sp)
    80005dc0:	6179                	addi	sp,sp,464
    80005dc2:	8082                	ret

0000000080005dc4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dc4:	7139                	addi	sp,sp,-64
    80005dc6:	fc06                	sd	ra,56(sp)
    80005dc8:	f822                	sd	s0,48(sp)
    80005dca:	f426                	sd	s1,40(sp)
    80005dcc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dce:	ffffc097          	auipc	ra,0xffffc
    80005dd2:	bde080e7          	jalr	-1058(ra) # 800019ac <myproc>
    80005dd6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005dd8:	fd840593          	addi	a1,s0,-40
    80005ddc:	4501                	li	a0,0
    80005dde:	ffffd097          	auipc	ra,0xffffd
    80005de2:	f62080e7          	jalr	-158(ra) # 80002d40 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005de6:	fc840593          	addi	a1,s0,-56
    80005dea:	fd040513          	addi	a0,s0,-48
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	db4080e7          	jalr	-588(ra) # 80004ba2 <pipealloc>
    return -1;
    80005df6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005df8:	0c054463          	bltz	a0,80005ec0 <sys_pipe+0xfc>
  fd0 = -1;
    80005dfc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e00:	fd043503          	ld	a0,-48(s0)
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	506080e7          	jalr	1286(ra) # 8000530a <fdalloc>
    80005e0c:	fca42223          	sw	a0,-60(s0)
    80005e10:	08054b63          	bltz	a0,80005ea6 <sys_pipe+0xe2>
    80005e14:	fc843503          	ld	a0,-56(s0)
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	4f2080e7          	jalr	1266(ra) # 8000530a <fdalloc>
    80005e20:	fca42023          	sw	a0,-64(s0)
    80005e24:	06054863          	bltz	a0,80005e94 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e28:	4691                	li	a3,4
    80005e2a:	fc440613          	addi	a2,s0,-60
    80005e2e:	fd843583          	ld	a1,-40(s0)
    80005e32:	68a8                	ld	a0,80(s1)
    80005e34:	ffffc097          	auipc	ra,0xffffc
    80005e38:	838080e7          	jalr	-1992(ra) # 8000166c <copyout>
    80005e3c:	02054063          	bltz	a0,80005e5c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e40:	4691                	li	a3,4
    80005e42:	fc040613          	addi	a2,s0,-64
    80005e46:	fd843583          	ld	a1,-40(s0)
    80005e4a:	0591                	addi	a1,a1,4
    80005e4c:	68a8                	ld	a0,80(s1)
    80005e4e:	ffffc097          	auipc	ra,0xffffc
    80005e52:	81e080e7          	jalr	-2018(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e56:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e58:	06055463          	bgez	a0,80005ec0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e5c:	fc442783          	lw	a5,-60(s0)
    80005e60:	07e9                	addi	a5,a5,26
    80005e62:	078e                	slli	a5,a5,0x3
    80005e64:	97a6                	add	a5,a5,s1
    80005e66:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e6a:	fc042783          	lw	a5,-64(s0)
    80005e6e:	07e9                	addi	a5,a5,26
    80005e70:	078e                	slli	a5,a5,0x3
    80005e72:	94be                	add	s1,s1,a5
    80005e74:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e78:	fd043503          	ld	a0,-48(s0)
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	9f6080e7          	jalr	-1546(ra) # 80004872 <fileclose>
    fileclose(wf);
    80005e84:	fc843503          	ld	a0,-56(s0)
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	9ea080e7          	jalr	-1558(ra) # 80004872 <fileclose>
    return -1;
    80005e90:	57fd                	li	a5,-1
    80005e92:	a03d                	j	80005ec0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e94:	fc442783          	lw	a5,-60(s0)
    80005e98:	0007c763          	bltz	a5,80005ea6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e9c:	07e9                	addi	a5,a5,26
    80005e9e:	078e                	slli	a5,a5,0x3
    80005ea0:	97a6                	add	a5,a5,s1
    80005ea2:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ea6:	fd043503          	ld	a0,-48(s0)
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	9c8080e7          	jalr	-1592(ra) # 80004872 <fileclose>
    fileclose(wf);
    80005eb2:	fc843503          	ld	a0,-56(s0)
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	9bc080e7          	jalr	-1604(ra) # 80004872 <fileclose>
    return -1;
    80005ebe:	57fd                	li	a5,-1
}
    80005ec0:	853e                	mv	a0,a5
    80005ec2:	70e2                	ld	ra,56(sp)
    80005ec4:	7442                	ld	s0,48(sp)
    80005ec6:	74a2                	ld	s1,40(sp)
    80005ec8:	6121                	addi	sp,sp,64
    80005eca:	8082                	ret
    80005ecc:	0000                	unimp
	...

0000000080005ed0 <kernelvec>:
    80005ed0:	7111                	addi	sp,sp,-256
    80005ed2:	e006                	sd	ra,0(sp)
    80005ed4:	e40a                	sd	sp,8(sp)
    80005ed6:	e80e                	sd	gp,16(sp)
    80005ed8:	ec12                	sd	tp,24(sp)
    80005eda:	f016                	sd	t0,32(sp)
    80005edc:	f41a                	sd	t1,40(sp)
    80005ede:	f81e                	sd	t2,48(sp)
    80005ee0:	fc22                	sd	s0,56(sp)
    80005ee2:	e0a6                	sd	s1,64(sp)
    80005ee4:	e4aa                	sd	a0,72(sp)
    80005ee6:	e8ae                	sd	a1,80(sp)
    80005ee8:	ecb2                	sd	a2,88(sp)
    80005eea:	f0b6                	sd	a3,96(sp)
    80005eec:	f4ba                	sd	a4,104(sp)
    80005eee:	f8be                	sd	a5,112(sp)
    80005ef0:	fcc2                	sd	a6,120(sp)
    80005ef2:	e146                	sd	a7,128(sp)
    80005ef4:	e54a                	sd	s2,136(sp)
    80005ef6:	e94e                	sd	s3,144(sp)
    80005ef8:	ed52                	sd	s4,152(sp)
    80005efa:	f156                	sd	s5,160(sp)
    80005efc:	f55a                	sd	s6,168(sp)
    80005efe:	f95e                	sd	s7,176(sp)
    80005f00:	fd62                	sd	s8,184(sp)
    80005f02:	e1e6                	sd	s9,192(sp)
    80005f04:	e5ea                	sd	s10,200(sp)
    80005f06:	e9ee                	sd	s11,208(sp)
    80005f08:	edf2                	sd	t3,216(sp)
    80005f0a:	f1f6                	sd	t4,224(sp)
    80005f0c:	f5fa                	sd	t5,232(sp)
    80005f0e:	f9fe                	sd	t6,240(sp)
    80005f10:	c3ffc0ef          	jal	ra,80002b4e <kerneltrap>
    80005f14:	6082                	ld	ra,0(sp)
    80005f16:	6122                	ld	sp,8(sp)
    80005f18:	61c2                	ld	gp,16(sp)
    80005f1a:	7282                	ld	t0,32(sp)
    80005f1c:	7322                	ld	t1,40(sp)
    80005f1e:	73c2                	ld	t2,48(sp)
    80005f20:	7462                	ld	s0,56(sp)
    80005f22:	6486                	ld	s1,64(sp)
    80005f24:	6526                	ld	a0,72(sp)
    80005f26:	65c6                	ld	a1,80(sp)
    80005f28:	6666                	ld	a2,88(sp)
    80005f2a:	7686                	ld	a3,96(sp)
    80005f2c:	7726                	ld	a4,104(sp)
    80005f2e:	77c6                	ld	a5,112(sp)
    80005f30:	7866                	ld	a6,120(sp)
    80005f32:	688a                	ld	a7,128(sp)
    80005f34:	692a                	ld	s2,136(sp)
    80005f36:	69ca                	ld	s3,144(sp)
    80005f38:	6a6a                	ld	s4,152(sp)
    80005f3a:	7a8a                	ld	s5,160(sp)
    80005f3c:	7b2a                	ld	s6,168(sp)
    80005f3e:	7bca                	ld	s7,176(sp)
    80005f40:	7c6a                	ld	s8,184(sp)
    80005f42:	6c8e                	ld	s9,192(sp)
    80005f44:	6d2e                	ld	s10,200(sp)
    80005f46:	6dce                	ld	s11,208(sp)
    80005f48:	6e6e                	ld	t3,216(sp)
    80005f4a:	7e8e                	ld	t4,224(sp)
    80005f4c:	7f2e                	ld	t5,232(sp)
    80005f4e:	7fce                	ld	t6,240(sp)
    80005f50:	6111                	addi	sp,sp,256
    80005f52:	10200073          	sret
    80005f56:	00000013          	nop
    80005f5a:	00000013          	nop
    80005f5e:	0001                	nop

0000000080005f60 <timervec>:
    80005f60:	34051573          	csrrw	a0,mscratch,a0
    80005f64:	e10c                	sd	a1,0(a0)
    80005f66:	e510                	sd	a2,8(a0)
    80005f68:	e914                	sd	a3,16(a0)
    80005f6a:	6d0c                	ld	a1,24(a0)
    80005f6c:	7110                	ld	a2,32(a0)
    80005f6e:	6194                	ld	a3,0(a1)
    80005f70:	96b2                	add	a3,a3,a2
    80005f72:	e194                	sd	a3,0(a1)
    80005f74:	4589                	li	a1,2
    80005f76:	14459073          	csrw	sip,a1
    80005f7a:	6914                	ld	a3,16(a0)
    80005f7c:	6510                	ld	a2,8(a0)
    80005f7e:	610c                	ld	a1,0(a0)
    80005f80:	34051573          	csrrw	a0,mscratch,a0
    80005f84:	30200073          	mret
	...

0000000080005f8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f8a:	1141                	addi	sp,sp,-16
    80005f8c:	e422                	sd	s0,8(sp)
    80005f8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f90:	0c0007b7          	lui	a5,0xc000
    80005f94:	4705                	li	a4,1
    80005f96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f98:	c3d8                	sw	a4,4(a5)
}
    80005f9a:	6422                	ld	s0,8(sp)
    80005f9c:	0141                	addi	sp,sp,16
    80005f9e:	8082                	ret

0000000080005fa0 <plicinithart>:

void
plicinithart(void)
{
    80005fa0:	1141                	addi	sp,sp,-16
    80005fa2:	e406                	sd	ra,8(sp)
    80005fa4:	e022                	sd	s0,0(sp)
    80005fa6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	9d8080e7          	jalr	-1576(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fb0:	0085171b          	slliw	a4,a0,0x8
    80005fb4:	0c0027b7          	lui	a5,0xc002
    80005fb8:	97ba                	add	a5,a5,a4
    80005fba:	40200713          	li	a4,1026
    80005fbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fc2:	00d5151b          	slliw	a0,a0,0xd
    80005fc6:	0c2017b7          	lui	a5,0xc201
    80005fca:	97aa                	add	a5,a5,a0
    80005fcc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret

0000000080005fd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fd8:	1141                	addi	sp,sp,-16
    80005fda:	e406                	sd	ra,8(sp)
    80005fdc:	e022                	sd	s0,0(sp)
    80005fde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe0:	ffffc097          	auipc	ra,0xffffc
    80005fe4:	9a0080e7          	jalr	-1632(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fe8:	00d5151b          	slliw	a0,a0,0xd
    80005fec:	0c2017b7          	lui	a5,0xc201
    80005ff0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005ff2:	43c8                	lw	a0,4(a5)
    80005ff4:	60a2                	ld	ra,8(sp)
    80005ff6:	6402                	ld	s0,0(sp)
    80005ff8:	0141                	addi	sp,sp,16
    80005ffa:	8082                	ret

0000000080005ffc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ffc:	1101                	addi	sp,sp,-32
    80005ffe:	ec06                	sd	ra,24(sp)
    80006000:	e822                	sd	s0,16(sp)
    80006002:	e426                	sd	s1,8(sp)
    80006004:	1000                	addi	s0,sp,32
    80006006:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	978080e7          	jalr	-1672(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006010:	00d5151b          	slliw	a0,a0,0xd
    80006014:	0c2017b7          	lui	a5,0xc201
    80006018:	97aa                	add	a5,a5,a0
    8000601a:	c3c4                	sw	s1,4(a5)
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6105                	addi	sp,sp,32
    80006024:	8082                	ret

0000000080006026 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006026:	1141                	addi	sp,sp,-16
    80006028:	e406                	sd	ra,8(sp)
    8000602a:	e022                	sd	s0,0(sp)
    8000602c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000602e:	479d                	li	a5,7
    80006030:	04a7cc63          	blt	a5,a0,80006088 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006034:	0001d797          	auipc	a5,0x1d
    80006038:	a1c78793          	addi	a5,a5,-1508 # 80022a50 <disk>
    8000603c:	97aa                	add	a5,a5,a0
    8000603e:	0187c783          	lbu	a5,24(a5)
    80006042:	ebb9                	bnez	a5,80006098 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006044:	00451693          	slli	a3,a0,0x4
    80006048:	0001d797          	auipc	a5,0x1d
    8000604c:	a0878793          	addi	a5,a5,-1528 # 80022a50 <disk>
    80006050:	6398                	ld	a4,0(a5)
    80006052:	9736                	add	a4,a4,a3
    80006054:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006058:	6398                	ld	a4,0(a5)
    8000605a:	9736                	add	a4,a4,a3
    8000605c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006060:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006064:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006068:	97aa                	add	a5,a5,a0
    8000606a:	4705                	li	a4,1
    8000606c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006070:	0001d517          	auipc	a0,0x1d
    80006074:	9f850513          	addi	a0,a0,-1544 # 80022a68 <disk+0x18>
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	064080e7          	jalr	100(ra) # 800020dc <wakeup>
}
    80006080:	60a2                	ld	ra,8(sp)
    80006082:	6402                	ld	s0,0(sp)
    80006084:	0141                	addi	sp,sp,16
    80006086:	8082                	ret
    panic("free_desc 1");
    80006088:	00002517          	auipc	a0,0x2
    8000608c:	6d850513          	addi	a0,a0,1752 # 80008760 <syscalls+0x310>
    80006090:	ffffa097          	auipc	ra,0xffffa
    80006094:	4b0080e7          	jalr	1200(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	6d850513          	addi	a0,a0,1752 # 80008770 <syscalls+0x320>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	4a0080e7          	jalr	1184(ra) # 80000540 <panic>

00000000800060a8 <virtio_disk_init>:
{
    800060a8:	1101                	addi	sp,sp,-32
    800060aa:	ec06                	sd	ra,24(sp)
    800060ac:	e822                	sd	s0,16(sp)
    800060ae:	e426                	sd	s1,8(sp)
    800060b0:	e04a                	sd	s2,0(sp)
    800060b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060b4:	00002597          	auipc	a1,0x2
    800060b8:	6cc58593          	addi	a1,a1,1740 # 80008780 <syscalls+0x330>
    800060bc:	0001d517          	auipc	a0,0x1d
    800060c0:	abc50513          	addi	a0,a0,-1348 # 80022b78 <disk+0x128>
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	a82080e7          	jalr	-1406(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060cc:	100017b7          	lui	a5,0x10001
    800060d0:	4398                	lw	a4,0(a5)
    800060d2:	2701                	sext.w	a4,a4
    800060d4:	747277b7          	lui	a5,0x74727
    800060d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060dc:	14f71b63          	bne	a4,a5,80006232 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060e0:	100017b7          	lui	a5,0x10001
    800060e4:	43dc                	lw	a5,4(a5)
    800060e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060e8:	4709                	li	a4,2
    800060ea:	14e79463          	bne	a5,a4,80006232 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060ee:	100017b7          	lui	a5,0x10001
    800060f2:	479c                	lw	a5,8(a5)
    800060f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060f6:	12e79e63          	bne	a5,a4,80006232 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060fa:	100017b7          	lui	a5,0x10001
    800060fe:	47d8                	lw	a4,12(a5)
    80006100:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006102:	554d47b7          	lui	a5,0x554d4
    80006106:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000610a:	12f71463          	bne	a4,a5,80006232 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000610e:	100017b7          	lui	a5,0x10001
    80006112:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006116:	4705                	li	a4,1
    80006118:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611a:	470d                	li	a4,3
    8000611c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000611e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006120:	c7ffe6b7          	lui	a3,0xc7ffe
    80006124:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbbcf>
    80006128:	8f75                	and	a4,a4,a3
    8000612a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000612c:	472d                	li	a4,11
    8000612e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006130:	5bbc                	lw	a5,112(a5)
    80006132:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006136:	8ba1                	andi	a5,a5,8
    80006138:	10078563          	beqz	a5,80006242 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006144:	43fc                	lw	a5,68(a5)
    80006146:	2781                	sext.w	a5,a5
    80006148:	10079563          	bnez	a5,80006252 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000614c:	100017b7          	lui	a5,0x10001
    80006150:	5bdc                	lw	a5,52(a5)
    80006152:	2781                	sext.w	a5,a5
  if(max == 0)
    80006154:	10078763          	beqz	a5,80006262 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006158:	471d                	li	a4,7
    8000615a:	10f77c63          	bgeu	a4,a5,80006272 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000615e:	ffffb097          	auipc	ra,0xffffb
    80006162:	988080e7          	jalr	-1656(ra) # 80000ae6 <kalloc>
    80006166:	0001d497          	auipc	s1,0x1d
    8000616a:	8ea48493          	addi	s1,s1,-1814 # 80022a50 <disk>
    8000616e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80006178:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000617a:	ffffb097          	auipc	ra,0xffffb
    8000617e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80006182:	87aa                	mv	a5,a0
    80006184:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006186:	6088                	ld	a0,0(s1)
    80006188:	cd6d                	beqz	a0,80006282 <virtio_disk_init+0x1da>
    8000618a:	0001d717          	auipc	a4,0x1d
    8000618e:	8ce73703          	ld	a4,-1842(a4) # 80022a58 <disk+0x8>
    80006192:	cb65                	beqz	a4,80006282 <virtio_disk_init+0x1da>
    80006194:	c7fd                	beqz	a5,80006282 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006196:	6605                	lui	a2,0x1
    80006198:	4581                	li	a1,0
    8000619a:	ffffb097          	auipc	ra,0xffffb
    8000619e:	b38080e7          	jalr	-1224(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800061a2:	0001d497          	auipc	s1,0x1d
    800061a6:	8ae48493          	addi	s1,s1,-1874 # 80022a50 <disk>
    800061aa:	6605                	lui	a2,0x1
    800061ac:	4581                	li	a1,0
    800061ae:	6488                	ld	a0,8(s1)
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	b22080e7          	jalr	-1246(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800061b8:	6605                	lui	a2,0x1
    800061ba:	4581                	li	a1,0
    800061bc:	6888                	ld	a0,16(s1)
    800061be:	ffffb097          	auipc	ra,0xffffb
    800061c2:	b14080e7          	jalr	-1260(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061c6:	100017b7          	lui	a5,0x10001
    800061ca:	4721                	li	a4,8
    800061cc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061ce:	4098                	lw	a4,0(s1)
    800061d0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061d4:	40d8                	lw	a4,4(s1)
    800061d6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061da:	6498                	ld	a4,8(s1)
    800061dc:	0007069b          	sext.w	a3,a4
    800061e0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061e4:	9701                	srai	a4,a4,0x20
    800061e6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061ea:	6898                	ld	a4,16(s1)
    800061ec:	0007069b          	sext.w	a3,a4
    800061f0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800061f4:	9701                	srai	a4,a4,0x20
    800061f6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800061fa:	4705                	li	a4,1
    800061fc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800061fe:	00e48c23          	sb	a4,24(s1)
    80006202:	00e48ca3          	sb	a4,25(s1)
    80006206:	00e48d23          	sb	a4,26(s1)
    8000620a:	00e48da3          	sb	a4,27(s1)
    8000620e:	00e48e23          	sb	a4,28(s1)
    80006212:	00e48ea3          	sb	a4,29(s1)
    80006216:	00e48f23          	sb	a4,30(s1)
    8000621a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000621e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006222:	0727a823          	sw	s2,112(a5)
}
    80006226:	60e2                	ld	ra,24(sp)
    80006228:	6442                	ld	s0,16(sp)
    8000622a:	64a2                	ld	s1,8(sp)
    8000622c:	6902                	ld	s2,0(sp)
    8000622e:	6105                	addi	sp,sp,32
    80006230:	8082                	ret
    panic("could not find virtio disk");
    80006232:	00002517          	auipc	a0,0x2
    80006236:	55e50513          	addi	a0,a0,1374 # 80008790 <syscalls+0x340>
    8000623a:	ffffa097          	auipc	ra,0xffffa
    8000623e:	306080e7          	jalr	774(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	56e50513          	addi	a0,a0,1390 # 800087b0 <syscalls+0x360>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f6080e7          	jalr	758(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006252:	00002517          	auipc	a0,0x2
    80006256:	57e50513          	addi	a0,a0,1406 # 800087d0 <syscalls+0x380>
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	2e6080e7          	jalr	742(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	58e50513          	addi	a0,a0,1422 # 800087f0 <syscalls+0x3a0>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d6080e7          	jalr	726(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	59e50513          	addi	a0,a0,1438 # 80008810 <syscalls+0x3c0>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c6080e7          	jalr	710(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	5ae50513          	addi	a0,a0,1454 # 80008830 <syscalls+0x3e0>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b6080e7          	jalr	694(ra) # 80000540 <panic>

0000000080006292 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006292:	7119                	addi	sp,sp,-128
    80006294:	fc86                	sd	ra,120(sp)
    80006296:	f8a2                	sd	s0,112(sp)
    80006298:	f4a6                	sd	s1,104(sp)
    8000629a:	f0ca                	sd	s2,96(sp)
    8000629c:	ecce                	sd	s3,88(sp)
    8000629e:	e8d2                	sd	s4,80(sp)
    800062a0:	e4d6                	sd	s5,72(sp)
    800062a2:	e0da                	sd	s6,64(sp)
    800062a4:	fc5e                	sd	s7,56(sp)
    800062a6:	f862                	sd	s8,48(sp)
    800062a8:	f466                	sd	s9,40(sp)
    800062aa:	f06a                	sd	s10,32(sp)
    800062ac:	ec6e                	sd	s11,24(sp)
    800062ae:	0100                	addi	s0,sp,128
    800062b0:	8aaa                	mv	s5,a0
    800062b2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062b4:	00c52d03          	lw	s10,12(a0)
    800062b8:	001d1d1b          	slliw	s10,s10,0x1
    800062bc:	1d02                	slli	s10,s10,0x20
    800062be:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800062c2:	0001d517          	auipc	a0,0x1d
    800062c6:	8b650513          	addi	a0,a0,-1866 # 80022b78 <disk+0x128>
    800062ca:	ffffb097          	auipc	ra,0xffffb
    800062ce:	90c080e7          	jalr	-1780(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800062d2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062d4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062d6:	0001cb97          	auipc	s7,0x1c
    800062da:	77ab8b93          	addi	s7,s7,1914 # 80022a50 <disk>
  for(int i = 0; i < 3; i++){
    800062de:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062e0:	0001dc97          	auipc	s9,0x1d
    800062e4:	898c8c93          	addi	s9,s9,-1896 # 80022b78 <disk+0x128>
    800062e8:	a08d                	j	8000634a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062ea:	00fb8733          	add	a4,s7,a5
    800062ee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800062f2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800062f4:	0207c563          	bltz	a5,8000631e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800062f8:	2905                	addiw	s2,s2,1
    800062fa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800062fc:	05690c63          	beq	s2,s6,80006354 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006300:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006302:	0001c717          	auipc	a4,0x1c
    80006306:	74e70713          	addi	a4,a4,1870 # 80022a50 <disk>
    8000630a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000630c:	01874683          	lbu	a3,24(a4)
    80006310:	fee9                	bnez	a3,800062ea <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006312:	2785                	addiw	a5,a5,1
    80006314:	0705                	addi	a4,a4,1
    80006316:	fe979be3          	bne	a5,s1,8000630c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000631a:	57fd                	li	a5,-1
    8000631c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000631e:	01205d63          	blez	s2,80006338 <virtio_disk_rw+0xa6>
    80006322:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006324:	000a2503          	lw	a0,0(s4)
    80006328:	00000097          	auipc	ra,0x0
    8000632c:	cfe080e7          	jalr	-770(ra) # 80006026 <free_desc>
      for(int j = 0; j < i; j++)
    80006330:	2d85                	addiw	s11,s11,1
    80006332:	0a11                	addi	s4,s4,4
    80006334:	ff2d98e3          	bne	s11,s2,80006324 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006338:	85e6                	mv	a1,s9
    8000633a:	0001c517          	auipc	a0,0x1c
    8000633e:	72e50513          	addi	a0,a0,1838 # 80022a68 <disk+0x18>
    80006342:	ffffc097          	auipc	ra,0xffffc
    80006346:	d36080e7          	jalr	-714(ra) # 80002078 <sleep>
  for(int i = 0; i < 3; i++){
    8000634a:	f8040a13          	addi	s4,s0,-128
{
    8000634e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006350:	894e                	mv	s2,s3
    80006352:	b77d                	j	80006300 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006354:	f8042503          	lw	a0,-128(s0)
    80006358:	00a50713          	addi	a4,a0,10
    8000635c:	0712                	slli	a4,a4,0x4

  if(write)
    8000635e:	0001c797          	auipc	a5,0x1c
    80006362:	6f278793          	addi	a5,a5,1778 # 80022a50 <disk>
    80006366:	00e786b3          	add	a3,a5,a4
    8000636a:	01803633          	snez	a2,s8
    8000636e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006370:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006374:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006378:	f6070613          	addi	a2,a4,-160
    8000637c:	6394                	ld	a3,0(a5)
    8000637e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006380:	00870593          	addi	a1,a4,8
    80006384:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006386:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006388:	0007b803          	ld	a6,0(a5)
    8000638c:	9642                	add	a2,a2,a6
    8000638e:	46c1                	li	a3,16
    80006390:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006392:	4585                	li	a1,1
    80006394:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006398:	f8442683          	lw	a3,-124(s0)
    8000639c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063a0:	0692                	slli	a3,a3,0x4
    800063a2:	9836                	add	a6,a6,a3
    800063a4:	058a8613          	addi	a2,s5,88
    800063a8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800063ac:	0007b803          	ld	a6,0(a5)
    800063b0:	96c2                	add	a3,a3,a6
    800063b2:	40000613          	li	a2,1024
    800063b6:	c690                	sw	a2,8(a3)
  if(write)
    800063b8:	001c3613          	seqz	a2,s8
    800063bc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063c0:	00166613          	ori	a2,a2,1
    800063c4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063c8:	f8842603          	lw	a2,-120(s0)
    800063cc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063d0:	00250693          	addi	a3,a0,2
    800063d4:	0692                	slli	a3,a3,0x4
    800063d6:	96be                	add	a3,a3,a5
    800063d8:	58fd                	li	a7,-1
    800063da:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063de:	0612                	slli	a2,a2,0x4
    800063e0:	9832                	add	a6,a6,a2
    800063e2:	f9070713          	addi	a4,a4,-112
    800063e6:	973e                	add	a4,a4,a5
    800063e8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800063ec:	6398                	ld	a4,0(a5)
    800063ee:	9732                	add	a4,a4,a2
    800063f0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063f2:	4609                	li	a2,2
    800063f4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800063f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063fc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006400:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006404:	6794                	ld	a3,8(a5)
    80006406:	0026d703          	lhu	a4,2(a3)
    8000640a:	8b1d                	andi	a4,a4,7
    8000640c:	0706                	slli	a4,a4,0x1
    8000640e:	96ba                	add	a3,a3,a4
    80006410:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006414:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006418:	6798                	ld	a4,8(a5)
    8000641a:	00275783          	lhu	a5,2(a4)
    8000641e:	2785                	addiw	a5,a5,1
    80006420:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006424:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006428:	100017b7          	lui	a5,0x10001
    8000642c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006430:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006434:	0001c917          	auipc	s2,0x1c
    80006438:	74490913          	addi	s2,s2,1860 # 80022b78 <disk+0x128>
  while(b->disk == 1) {
    8000643c:	4485                	li	s1,1
    8000643e:	00b79c63          	bne	a5,a1,80006456 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006442:	85ca                	mv	a1,s2
    80006444:	8556                	mv	a0,s5
    80006446:	ffffc097          	auipc	ra,0xffffc
    8000644a:	c32080e7          	jalr	-974(ra) # 80002078 <sleep>
  while(b->disk == 1) {
    8000644e:	004aa783          	lw	a5,4(s5)
    80006452:	fe9788e3          	beq	a5,s1,80006442 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006456:	f8042903          	lw	s2,-128(s0)
    8000645a:	00290713          	addi	a4,s2,2
    8000645e:	0712                	slli	a4,a4,0x4
    80006460:	0001c797          	auipc	a5,0x1c
    80006464:	5f078793          	addi	a5,a5,1520 # 80022a50 <disk>
    80006468:	97ba                	add	a5,a5,a4
    8000646a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000646e:	0001c997          	auipc	s3,0x1c
    80006472:	5e298993          	addi	s3,s3,1506 # 80022a50 <disk>
    80006476:	00491713          	slli	a4,s2,0x4
    8000647a:	0009b783          	ld	a5,0(s3)
    8000647e:	97ba                	add	a5,a5,a4
    80006480:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006484:	854a                	mv	a0,s2
    80006486:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000648a:	00000097          	auipc	ra,0x0
    8000648e:	b9c080e7          	jalr	-1124(ra) # 80006026 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006492:	8885                	andi	s1,s1,1
    80006494:	f0ed                	bnez	s1,80006476 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006496:	0001c517          	auipc	a0,0x1c
    8000649a:	6e250513          	addi	a0,a0,1762 # 80022b78 <disk+0x128>
    8000649e:	ffffa097          	auipc	ra,0xffffa
    800064a2:	7ec080e7          	jalr	2028(ra) # 80000c8a <release>
}
    800064a6:	70e6                	ld	ra,120(sp)
    800064a8:	7446                	ld	s0,112(sp)
    800064aa:	74a6                	ld	s1,104(sp)
    800064ac:	7906                	ld	s2,96(sp)
    800064ae:	69e6                	ld	s3,88(sp)
    800064b0:	6a46                	ld	s4,80(sp)
    800064b2:	6aa6                	ld	s5,72(sp)
    800064b4:	6b06                	ld	s6,64(sp)
    800064b6:	7be2                	ld	s7,56(sp)
    800064b8:	7c42                	ld	s8,48(sp)
    800064ba:	7ca2                	ld	s9,40(sp)
    800064bc:	7d02                	ld	s10,32(sp)
    800064be:	6de2                	ld	s11,24(sp)
    800064c0:	6109                	addi	sp,sp,128
    800064c2:	8082                	ret

00000000800064c4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064c4:	1101                	addi	sp,sp,-32
    800064c6:	ec06                	sd	ra,24(sp)
    800064c8:	e822                	sd	s0,16(sp)
    800064ca:	e426                	sd	s1,8(sp)
    800064cc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064ce:	0001c497          	auipc	s1,0x1c
    800064d2:	58248493          	addi	s1,s1,1410 # 80022a50 <disk>
    800064d6:	0001c517          	auipc	a0,0x1c
    800064da:	6a250513          	addi	a0,a0,1698 # 80022b78 <disk+0x128>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	6f8080e7          	jalr	1784(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064e6:	10001737          	lui	a4,0x10001
    800064ea:	533c                	lw	a5,96(a4)
    800064ec:	8b8d                	andi	a5,a5,3
    800064ee:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064f0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064f4:	689c                	ld	a5,16(s1)
    800064f6:	0204d703          	lhu	a4,32(s1)
    800064fa:	0027d783          	lhu	a5,2(a5)
    800064fe:	04f70863          	beq	a4,a5,8000654e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006502:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006506:	6898                	ld	a4,16(s1)
    80006508:	0204d783          	lhu	a5,32(s1)
    8000650c:	8b9d                	andi	a5,a5,7
    8000650e:	078e                	slli	a5,a5,0x3
    80006510:	97ba                	add	a5,a5,a4
    80006512:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006514:	00278713          	addi	a4,a5,2
    80006518:	0712                	slli	a4,a4,0x4
    8000651a:	9726                	add	a4,a4,s1
    8000651c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006520:	e721                	bnez	a4,80006568 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006522:	0789                	addi	a5,a5,2
    80006524:	0792                	slli	a5,a5,0x4
    80006526:	97a6                	add	a5,a5,s1
    80006528:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000652a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000652e:	ffffc097          	auipc	ra,0xffffc
    80006532:	bae080e7          	jalr	-1106(ra) # 800020dc <wakeup>

    disk.used_idx += 1;
    80006536:	0204d783          	lhu	a5,32(s1)
    8000653a:	2785                	addiw	a5,a5,1
    8000653c:	17c2                	slli	a5,a5,0x30
    8000653e:	93c1                	srli	a5,a5,0x30
    80006540:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006544:	6898                	ld	a4,16(s1)
    80006546:	00275703          	lhu	a4,2(a4)
    8000654a:	faf71ce3          	bne	a4,a5,80006502 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000654e:	0001c517          	auipc	a0,0x1c
    80006552:	62a50513          	addi	a0,a0,1578 # 80022b78 <disk+0x128>
    80006556:	ffffa097          	auipc	ra,0xffffa
    8000655a:	734080e7          	jalr	1844(ra) # 80000c8a <release>
}
    8000655e:	60e2                	ld	ra,24(sp)
    80006560:	6442                	ld	s0,16(sp)
    80006562:	64a2                	ld	s1,8(sp)
    80006564:	6105                	addi	sp,sp,32
    80006566:	8082                	ret
      panic("virtio_disk_intr status");
    80006568:	00002517          	auipc	a0,0x2
    8000656c:	2e050513          	addi	a0,a0,736 # 80008848 <syscalls+0x3f8>
    80006570:	ffffa097          	auipc	ra,0xffffa
    80006574:	fd0080e7          	jalr	-48(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
