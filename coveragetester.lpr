program CoverageTester;
{$mode delphi}{$h+}

uses
 QEMUVersatilePBCoverage,GlobalConfig,Platform,Logging,Serial,SysUtils,Classes,CoverageMap;

procedure StartLogging;
begin
 LOGGING_INCLUDE_COUNTER:=False;
 SERIAL_REGISTER_LOGGING:=True;
 SerialLoggingDeviceAdd(SerialDeviceGetDefault);
 SERIAL_REGISTER_LOGGING:=False;
 LoggingDeviceSetDefault(LoggingDeviceFindByType(LOGGING_TYPE_SERIAL));
end;

type
 PSubroutine = ^TSubroutine;
 TSubroutine = record
  Id:LongWord;
  Counter:LongWord;
  LastClock:LongWord;
  PrevClock:LongWord;
 end;

 TCoverageAnalyzer = record
  Meter:PCoverageMeter;
  EventsProcessed:LongWord;
  HighWater:LongWord;
  Subroutines:Array[0..MaxSubroutines - 1] of TSubroutine;
 end;

var
 I:Integer;
 Next:LongWord;
 CoverageAnalyzer:TCoverageAnalyzer;
 Sorter:TFPList;
 Clock:LongWord;
 LastSubroutineId:LongWord;
 SequenceNumber:LongWord;
 Formatted:String;
 IdleCalibrateSubroutine:PSubroutineDescriptor;
 ClockGetTotalSubroutine:PSubroutineDescriptor;

function CompareCounter(A,B:Pointer):Integer;
begin
 Result:=PSubroutine(A).Counter - PSubroutine(B).Counter;
 if Result = 0 then
  Result:=CompareStr(SubroutineDescriptors[PSubroutine(A).Id].Name,SubroutineDescriptors[PSubroutine(B).Id].Name);
end;

function BackLog:LongWord;
begin
 Result:=CoverageMeter.TraceCounter - CoverageAnalyzer.EventsProcessed;
end;

begin
  IdleCalibrateSubroutine:=SubroutineFindDescriptor('THREADS_$$_IDLECALIBRATE$');
  ClockGetTotalSubroutine:=SubroutineFindDescriptor('PLATFORMQEMUVPB_$$_QEMUVPBCLOCKGETTOTAL$');
  with CoverageAnalyzer do
   begin
    Meter:=@CoverageMeter;
    EventsProcessed:=0;
    HighWater:=0;
    for I:=Low(Subroutines) to High(Subroutines) do
     with Subroutines[I] do
      begin
       Id:=I;
       Counter:=0;
       LastClock:=0;
       PrevClock:=0;
      end;
   end;
 Sorter:=TFPList.Create;
 Clock:=0;
 LastSubroutineId:=$ffffffff;
 SequenceNumber:=0;
 StartLogging;
 while True do
  begin
    begin
     with CoverageAnalyzer do
      begin
       Next:=Meter.TraceCounter;
//     LoggingOutput(Format('%8d more events - total %d',[Next - EventsProcessed, Next]));
       try
        while EventsProcessed <> Next do
         begin
          with Meter.TraceBuffer[EventsProcessed and (TraceLength - 1)] do
           begin
           with Subroutines[SubroutineId] do
            begin
             if (EventsProcessed < 80000) and (SubroutineId <> LastSubroutineId) then
              begin
               if SubroutineDescriptors[SubroutineId].IsFunction then
                begin
                 if R0 < 1*1000*1000 then
                  Formatted:=Format('%8.8x/%6d',[R0,R0])
                 else
                  Formatted:=Format('%8.8x       ',[R0]);
                end
               else
                begin
                 Formatted:='               ';
                end;
               LoggingOutput(Format('%6d %s %s',[SequenceNumber,Formatted,SubroutineDescriptors[SubroutineId].Name]));
              end;
             Inc(SequenceNumber);
             if SubroutineId = IdleCalibrateSubroutine.Id then
              SequenceNumber:=100*1000;
             LastSubroutineId:=SubroutineId;
             if SubroutineId > HighWater then
              HighWater:=SubroutineId;
             if SubroutineId = ClockGetTotalSubroutine.Id then
              Clock:=R0;
             Inc(Counter);
             PrevClock:=LastClock;
             LastClock:=Clock;
//           if Counter = 1 then
//            LoggingOutput(Format('%8d id %4d %s',[Counter,SubroutineId,SubroutineDescriptors[SubroutineId].Name]));
             Inc(EventsProcessed);
             if EventsProcessed mod (4*1000*1000) = 0 then
              begin
//             asm
//              svc #5000 // batch log
//             end;
               LoggingOutput(Format('total %d high water %d',[EventsProcessed,HighWater]));
               Sorter.Clear;
               for I:=0 to HighWater do
                if (Subroutines[I].Counter > 0) and (Subroutines[I].Counter < 1000*1000) then
                 Sorter.Add(@Subroutines[I]);
               Sorter.Sort(CompareCounter);
               for I:=0 to Sorter.Count - 1 do
                with PSubroutine(Sorter.Items[I])^ do
                 LoggingOutput(Format('%8d %8d %s',[LastClock - PrevClock,Counter,SubroutineDescriptors[Id].Name]));
               for I:=0 to HighWater do
                Subroutines[I].Counter:=0;
               HighWater:=0;
               LoggingOutput(Format('back log %6d',[BackLog]));
              end;
           end;
           end;
         end;
       except on E:Exception do
        begin
         LoggingOutput(Format('',[]));
         LoggingOutput(Format('exception %s Next %d EventsProcessed %d',[E.Message,Next,EventsProcessed]));
         LoggingOutput(Format('',[]));
         EventsProcessed:=Next;
         Sleep(2*1000);
        end;
       end;
      end;
    end;
  end;
end.
