--
--  The author disclaims copyright to this source code.  In place of
--  a legal notice, here is a blessing:
--
--    May you do good and not evil.
--    May you find forgiveness for yourself and forgive others.
--    May you share freely, not taking more than you give.
--

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Command_Line;
with Ada.Exceptions;

with Setup;
with Options;
with Command_Line;
with Sessions;
with Cherry;
with Rules;
with Symbols;
with Parsers;
with Exceptions;
with Reports;
with States;
with Builds;

with Debugs;


procedure Cherry_Program is

   procedure Put_Blessing;
   procedure Put_Help;
   procedure Put_Version;
   procedure Put_Statistics (Session : in Sessions.Session_Type);


   procedure Put_Blessing is
      use Ada.Text_IO;
   begin
      Put_Line ("The author disclaims copyright to this source code.  In place of");
      Put_Line ("a legal notice, here is a blessing:");
      New_Line;
      Put_Line ("   May you do good and not evil.");
      Put_Line ("   May you find forgiveness for yourself and forgive others.");
      Put_Line ("   May you share freely, not taking more than you give.");
      New_Line;
   end Put_Blessing;


   procedure Put_Help is
   begin
      Cherry.Dummy;  -- XXX
      Reports.Dummy;
   end Put_Help;


   procedure Put_Version
   is
      use Ada.Text_IO, Setup;
      Version : constant String := Get_Program_Name & " (" & Get_Program_Version & ")";
      Build   : constant String := "Build (" & Get_Build_ISO8601_UTC & ")";
   begin
      Put_Line (Version);
      Put_Line (Build);
      New_Line;
   end Put_Version;


   procedure Put_Statistics (Session : in Sessions.Session_Type)
   is
      procedure Stats_Line (Text  : in String;
                            Value : in Integer);

      procedure Stats_Line (Text  : in String;
                            Value : in Integer)
      is
         use Ada.Text_IO;

         Line : String (1 .. 35) := (others => '.');
      begin
         Line (Line'First .. Text'Last) := Text;
         Line (Text'Last + 1) := ' ';
         Put (Line);
         Put (Integer'Image (Value));
         New_Line;
      end Stats_Line;

      use type Symbols.Symbol_Index;
   begin
      Ada.Text_IO.Put_Line ("Parser statistics:");
      Stats_Line ("terminal symbols", Integer (Session.N_Terminal));
      Stats_Line ("non-terminal symbols", Integer (Session.N_Symbol - Session.N_Terminal));
      Stats_Line ("total symbols", Integer (Session.N_Symbol));
      Stats_Line ("rules", Session.N_Rule);
      Stats_Line ("states", Integer (Session.Nx_State));
      Stats_Line ("conflicts", Session.N_Conflict);
      Stats_Line ("action table entries", Session.N_Action_Tab);
      Stats_Line ("lookahead table entries", Session.N_Lookahead_Tab);
      Stats_Line ("total table size (bytes)", Session.Table_Size);
   end Put_Statistics;


   use Ada.Command_Line;

   Parse_Success : Boolean;
begin
   Command_Line.Parse (Parse_Success);

   if not Parse_Success then
      Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   if Options.Show_Version then
      Put_Version;
      Put_Blessing;
      return;
   end if;

   if Options.Show_Help then
      Put_Help;
      return;
   end if;

   Options.Set_Language;

   declare
      use Ada.Strings.Unbounded;
      use Ada.Text_IO;
      use Symbols;
      use Rules;

      Session : aliased Sessions.Session_Type;

      Failure : Ada.Command_Line.Exit_Status renames Ada.Command_Line.Failure;

      Dummy_Symbol_Count : Symbol_Index;
   begin
      Session := Sessions.Clean_Session;
      Session.Error_Cnt := 0;

      --  Initialize the machine
      Sessions.Strsafe_Init;
      Symbols.Symbol_Init;
      States.Initialize;

      Session.Argv0           := To_Unbounded_String (Options.Program_Name.all);
      Session.File_Name       := To_Unbounded_String (Options.Input_File.all);
      Session.Basis_Flag      := Options.Basis_Flag;
      Session.No_Linenos_Flag := Options.No_Line_Nos;

      --  Extras.Symbol_Append (Key => "$");
      declare
         Dummy : constant Symbol_Access := Create ("$");
      begin
         null;
      end;

      --  Parse the input file
      Parsers.Parse (Session);

      if Session.Error_Cnt /= 0 then
         Ada.Command_Line.Set_Exit_Status (Failure);
         return;
      end if;

      if Session.N_Rule = 0 then
         Put_Line (Standard_Error, "Empty grammar.");
         Ada.Command_Line.Set_Exit_Status (Failure);
         return;
      end if;

      Session.Error_Symbol := Find ("error");

      --  Count and index the symbols of the grammar
--      Extras.Symbol_Append (Key => "{default}");
      declare
         Dummy : constant Symbol_Access := Create ("{default}");
      begin
         null;
      end;

--      Symbols.Symbol_Allocate (Ada.Containers.Count_Type (Extras.Symbol_Count));

      Ada.Text_IO.Put_Line ("jq_dump_symbols before sort");
--      Extras.JQ_Dump_Symbols;
      Symbols.JQ_Dump_Symbols (Mode => 1);

--      Extras.Fill_And_Sort;
      Symbols.Sort;

      Ada.Text_IO.Put_Line ("jq_dump_symbols after sort");
--      Extras.JQ_Dump_Symbols;
      Symbols.JQ_Dump_Symbols (0);

      declare
         Symbol_Count   : Natural;
         Terminal_Count : Natural;
      begin
         Symbols.Count_Symbols_And_Terminals (Symbol_Count   => Symbol_Count,
                                              Terminal_Count => Terminal_Count);
         Session.N_Symbol   := Symbol_Index (Symbol_Count);
         Session.N_Terminal := Symbol_Index (Terminal_Count);
         Ada.Text_IO.Put ("nsymbol:" & Natural'Image (Symbol_Count));
         Ada.Text_IO.Put ("  nterminal:" & Natural'Image (Terminal_Count));
         Ada.Text_IO.Put_Line (" ");
      end;

      --  Assign sequential rule numbers.  Start with 0.  Put rules that have no
      --  reduce action C-code associated with them last, so that the switch()
      --  statement that selects reduction actions will have a smaller jump table.

      Ada.Text_IO.Put_Line ("jq_dump_rules first");
      Debugs.JQ_Dump_Rules (Session, 0);

      Rules.Assing_Sequential_Rule_Numbers
        (Session.Rule,
         Session.Start_Rule);

      Ada.Text_IO.Put_Line ("jq_dump_rules second");
      Debugs.JQ_Dump_Rules (Session, 0);

      Session.Start_Rule := Session.Rule;
      Session.Rule       := Rule_Sort (Session.Rule);

      Ada.Text_IO.Put_Line ("jq_dump_rules third");
      Debugs.JQ_Dump_Rules (Session, 0);

      --  Generate a reprint of the grammar, if requested on the command line
      if Options.RP_Flag then
         Reports.Reprint (Session);
      else
         Builds.Reprint_Of_Grammar
           (Session,
            Base_Name     => "XXX",
            Token_Prefix  => "YYY",
            Terminal_Last => 999);
      end if;

      if Options.Statistics then
         Put_Statistics (Session);
      end if;

      if Session.N_Conflict > 0 then
         Put_Line
           (Standard_Error,
            Integer'Image (Session.N_Conflict) & " parsing conflicts.");
      end if;

      if
        Session.Error_Cnt  > 0 or
        Session.N_Conflict > 0
      then
         Ada.Command_Line.Set_Exit_Status (Failure);
         return;
      end if;
   end;
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);

exception

   when OCC : Command_Line.Parameter_Error =>
      Exceptions.Put_Message (OCC);


   when Occ : others =>
      Ada.Text_IO.Put_Line (Ada.Exceptions.Exception_Name (Occ));
      Ada.Text_IO.Put_Line (Ada.Exceptions.Exception_Message (Occ));
      Ada.Text_IO.Put_Line (Ada.Exceptions.Exception_Information (Occ));
      Exceptions.Put_Message (Occ);

end Cherry_Program;
