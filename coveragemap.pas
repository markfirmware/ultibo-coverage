unit CoverageMap;

interface

const
 MaxCounters=16*1024;

var
 SubroutineNames:Array[0..MaxCounters - 1] of String;

implementation

var
 Count:LongWord;

procedure AddFileName(FileName:String);
begin
end;

procedure AddSubroutine(Name:String);
begin
 SubroutineNames[Count]:=Name;
 Inc(Count);
end;

initialization
 Count:=0;
 {$i coveragemap.inc}
end.
