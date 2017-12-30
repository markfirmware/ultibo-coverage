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

 PCoverageMeter = ^TCoverageMeter;
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
        stmfd  r13!,{r0-r4,r14}
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
        and    r1,r2 // wrapped index
        add    r4,r4,r1,lsl #2 // r4 points to event record
        ldr    r1,[r14,#-4] // get svc instruction
        bic    r1,#0xFF000000 // just the svc code number
        str    r1,[r4,#TCoverageEvent.SubroutineId]
        str    r0,[r4,#TCoverageEvent.R0]
        str    r2,[r3,#TCoverageMeter.TraceCounter]
        ldmfd  r13!,{r0-r4,r15}^
end;

const
 MaxSubroutines = 16*1024;

type
 PSubroutine = ^TSubroutine;
 TSubroutine = record
  Id:LongWord;
  Counter:LongWord;
 end;

function CompareCounter(A,B:Pointer):Integer;
begin
 Result:=PSubroutine(A).Counter - PSubroutine(B).Counter;
end;

type
 TCoverageAnalyzer = record
  Meter:PCoverageMeter;
  EventsProcessed:LongWord;
  Subroutines:Array[0..MaxSubroutines - 1] of TSubroutine;
 end;

var
 I:Integer;
 Next:LongWord;
 CoverageAnalyzers:Array[0..3] of TCoverageAnalyzer;
 CpuId:LongWord;
 Sorter:TFPList;

begin
 for CpuId:=0 to 3 do
  with CoverageAnalyzers[CpuId] do
   begin
    Meter:=@CoverageMeters[CpuId];
    Meter.TraceCounter:=0;
    EventsProcessed:=0;
    for I:=Low(Subroutines) to High(Subroutines) do
     with Subroutines[I] do
      begin
       Id:=I;
       Counter:=0;
      end;
   end;
 Sorter:=TFPList.Create;
 VectorTableSetEntry(VECTOR_TABLE_ENTRY_ARM_SWI,PtrUInt(@CoverageSwiHandler));
 StartLogging;
 while True do
  begin
   Sleep(1*1000);
// LoggingOutput(Format('cpu 0:%d 1:%d 2:%d 3:%d',[CoverageMeters[0].TraceCounter,CoverageMeters[1].TraceCounter,CoverageMeters[2].TraceCounter,CoverageMeters[3].TraceCounter]));
   for CpuId:=0 to 3 do
    begin
     with CoverageAnalyzers[CpuId] do
      begin
       Next:=Meter.TraceCounter;
//     LoggingOutput(Format('%d %8d more events - total %d',[CpuId,Next - EventsProcessed, Next]));
       try
        while EventsProcessed <> Next do
         begin
          with Meter.TraceBuffer[EventsProcessed and (MaxSubroutines - 1)] do
           with Subroutines[SubroutineId] do
            begin
             Inc(Counter);
//           if Counter = 1 then
//            LoggingOutput(Format('%d %8d id %4d %s',[CpuId,Counter,SubroutineId,SubroutineNames[SubroutineId]]));
             Inc(EventsProcessed);
             if EventsProcessed mod (1000*1000) = 0 then
              begin
               LoggingOutput(Format('total %d %d',[CpuId,EventsProcessed]));
               Sorter.Clear;
               for I:=0 to MaxSubroutines do
                if Subroutines[I].Counter <> 0 then
                 Sorter.Add(@Subroutines[I]);
               Sorter.Sort(CompareCounter);
               for I:=0 to Sorter.Count - 1 do
                with PSubroutine(Sorter.Items[I])^ do
                 LoggingOutput(Format('%8d %s',[Counter,SubroutineNames[Id]]));
               for I:=0 to MaxSubroutines do
                Subroutines[I].Counter:=0;
              end;
           end;
         end;
       except on E:Exception do
        begin
         EventsProcessed:=Next;
         LoggingOutput(Format('',[]));
         LoggingOutput(Format('exception %s',[E.Message]));
         LoggingOutput(Format('',[]));
         Sleep(5*1000);
        end;
       end;
      end;
    end;
  end;
end.
