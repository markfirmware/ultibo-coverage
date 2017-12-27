program CoverageTester;
{$mode delphi}{$h+}

uses
 QEMUVersatilePB,VersatilePb,
 Classes,Console,GlobalConfig,GlobalConst,GlobalTypes,
 Logging,Platform,Serial,StrUtils,SysUtils,Threads,Ultibo;

procedure StartLogging;
begin
 LOGGING_INCLUDE_COUNTER:=FALSE;
 LOGGING_INCLUDE_TICKCOUNT:=TRUE;
 SERIAL_REGISTER_LOGGING:=True;
 SerialLoggingDeviceAdd(SerialDeviceGetDefault);
 SERIAL_REGISTER_LOGGING:=False;
 LoggingDeviceSetDefault(LoggingDeviceFindByType(LOGGING_TYPE_SERIAL));
end;

var
 CoverageCounters:Array[0..3] of LongWord;

const
 ARMV7_CP15_C0_MPID_CPUID_MASK        = (3 shl 0);

procedure CoverageSwiHandler; assembler; nostackframe;
asm
        stmfd  r13!,{r0-r2,r14}
        //Read the Multiprocessor Affinity (MPIDR) register from the system control coprocessor CP15
        mrc    p15,#0,r0,cr0,cr0,#5
        //Mask off the CPUID value
        and    r0,r0,#ARMV7_CP15_C0_MPID_CPUID_MASK
        ldr    r1,=CoverageCounters
        ldr    r2,[r1,r0,lsl #2]
        add    r2,#1
        str    r2,[r1,r0,lsl #2]
        ldmfd  r13!,{r0-r2,r15}^
end;

var
 I:Integer;

begin
 for I:=Low(CoverageCounters) to High(CoverageCounters) do
  Coveragecounters[I]:=0;
 VectorTableSetEntry(VECTOR_TABLE_ENTRY_ARM_SWI,PtrUInt(@CoverageSwiHandler));
 StartLogging;
 while True do
  begin
   Sleep(1*1000);
   LoggingOutput(Format('cpu 0:%d 1:%d 2:%d 3:%d',[CoverageCounters[0],CoverageCounters[1],CoverageCounters[2],CoverageCounters[3]]));
  end;
end.
