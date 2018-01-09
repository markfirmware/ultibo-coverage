unit CoverageMap;
{$mode delphi}{$h+}

interface
const
 MaxSubroutines=20*1000;

type
 PSubroutineDescriptor = ^TSubroutineDescriptor;
 TSubroutineDescriptor = record
  Id:LongWord;
  Name:String;
  IsFunction:Boolean;
 end;

function SubroutineFindDescriptor(Name:String):PSubroutineDescriptor;

var
 SubroutineDescriptors:Array[0..MaxSubroutines - 1] of TSubroutineDescriptor;

implementation
uses
 SysUtils;

var
 Count:LongWord;

function SubroutineFindDescriptor(Name:String):PSubroutineDescriptor;
var
 I:Integer;
begin
 for I:=Low(SubroutineDescriptors) to High(SubroutineDescriptors) do
  if AnsiPos(Name,SubroutineDescriptors[I].Name) <> 0  then
   begin
    Result:=@SubroutineDescriptors[I];
    exit;
   end;
 Result:=nil;
end;

procedure AddFileName(FileName:String);
begin
end;

procedure AddSubroutine(Name:String);
var
 Index:Integer;
begin
 Name:=Trim(Name);
 SubroutineDescriptors[Count].Id:=Count;
 SubroutineDescriptors[Count].Name:=Name;
 SubroutineDescriptors[Count].IsFunction:=False;
 Index:=AnsiPos('$$',Name);
 if Index <> 0 then
  if AnsiPos('$$',Copy(Name,Index + 2,Length(Name) - (Index + 2))) <> 0 then
   SubroutineDescriptors[Count].IsFunction:=True;
 Inc(Count);
end;

initialization
 Count:=0;
 {$i coveragemap.inc}
 while Count < MaxSubroutines do
  AddSubroutine(Format('entry %5d',[Count]));
end.
