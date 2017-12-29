program CoverageTester;
{$mode delphi}{$h+}

uses
 QEMUVersatilePB,VersatilePb,
 Classes,Console,GlobalConfig,GlobalConst,GlobalTypes,
 Logging,Platform,Serial,StrUtils,SysUtils,Threads,Ultibo,
 CoverageMap;

procedure StartLogging;
begin
 LOGGING_INCLUDE_COUNTER:=FALSE;
 LOGGING_INCLUDE_TICKCOUNT:=TRUE;
 SERIAL_REGISTER_LOGGING:=True;
 SerialLoggingDeviceAdd(SerialDeviceGetDefault);
 SERIAL_REGISTER_LOGGING:=False;
 LoggingDeviceSetDefault(LoggingDeviceFindByType(LOGGING_TYPE_SERIAL));
end;

const
 TraceLength = 2*1024*1024;

type
 TCoverageEvent = record
  SubroutineId:LongWord;
  R0:LongWord;
 end;

 TCoverageMeter = record
  TraceCounter:LongWord;
  TraceBuffer:Array[0..TraceLength - 1] of TCoverageEvent;
  RecordEnd:LongWord;
 end;

var
 CoverageMeters:Array[0..3] of TCoverageMeter;

const
 ARMV7_CP15_C0_MPID_CPUID_MASK        = (3 shl 0);

procedure CoverageSwiHandler; assembler; nostackframe;
asm
        stmfd  r13!,{r0-r5,r14}
        //Read the Multiprocessor Affinity (MPIDR) register from the system control coprocessor CP15
        mrc    p15,#0,r3,cr0,cr0,#5
        //Mask off the CPUID value
        and    r3,#ARMV7_CP15_C0_MPID_CPUID_MASK
        ldr    r1,=TCoverageMeter.RecordEnd-4
        mul    r3,r1,r3
        ldr    r1,=CoverageMeters
        add    r3,r1 // r3 is the meter
        add    r4,r3,#TCoverageMeter.TraceBuffer // r4 is the trace buffer
        ldr    r2,[r3,#TCoverageMeter.TraceCounter]
        add    r2,#1 // r2 is the event counter
        ldr    r1,=TraceLength-1
        and    r1,r2 // r1 is wrapped index
        add    r4,r4,r1,lsl #2 // r4 points to event record
        ldr    r5,[r14,#-4] // get svc instruction
        bic    r5,#0xFF000000 // just the svc code number
        str    r5,[r4,#TCoverageEvent.SubroutineId]
        str    r0,[r4,#TCoverageEvent.R0]
        str    r2,[r3,#TCoverageMeter.TraceCounter]
        ldmfd  r13!,{r0-r5,r15}^
end;

const
 MaxCounters = 16*1024;

var
 I:Integer;
 Next:LongWord;
 EventsProcessed:LongWord;
 Counters:Array[0..MaxCounters - 1] of LongWord;

begin
 for I:=Low(CoverageMeters) to High(CoverageMeters) do
  with CoverageMeters[I] do
   TraceCounter:=0;
 for I:=Low(Counters) to High(Counters) do
  Counters[I]:=0;
 EventsProcessed:=0;
 VectorTableSetEntry(VECTOR_TABLE_ENTRY_ARM_SWI,PtrUInt(@CoverageSwiHandler));
 StartLogging;
 while True do
  begin
   Sleep(1*1000);
// LoggingOutput(Format('cpu 0:%d 1:%d 2:%d 3:%d',[CoverageMeters[0].TraceCounter,CoverageMeters[1].TraceCounter,CoverageMeters[2].TraceCounter,CoverageMeters[3].TraceCounter]));
   with CoverageMeters[0] do
    begin
     Next:=TraceCounter;
     LoggingOutput(Format('%8d more events - total %d',[Next - EventsProcessed, Next]));
     try
      while EventsProcessed <> Next do
       begin
        with TraceBuffer[EventsProcessed and (MaxCounters - 1)] do
         begin
          Inc(Counters[SubroutineId]);
           if Counters[SubroutineId] mod (50*1000) = 0 then
            LoggingOutput(Format('%8d id %4d %s',[Counters[SubroutineId],SubroutineId,SubroutineNames[SubroutineId]]));
           Inc(EventsProcessed);
         end;
       end;
     except on E:Exception do
      begin
       LoggingOutput(Format('',[]));
       LoggingOutput(Format('exception %s',[E.Message]));
       LoggingOutput(Format('',[]));
       Sleep(5*1000);
      end;
     end;
    end;
   EventsProcessed:=Next;
  end;
end.
