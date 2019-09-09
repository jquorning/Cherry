--
--
--

with Ada.Strings.Unbounded;

with Rules;
with Symbols;
with Sets;
with Errors;
with Lemon_Bind;
with Configs;

package body Builds is


   procedure Find_Rule_Precedences (Lemon : in out Lime.Lemon_Record)
   is
      use Rules;
      use Symbols;

      RP : Rule_Access;
   begin
      RP := Lemon.Rule;
      while RP /= null loop
         if RP.Prec_Sym = null then
            for I in RP.RHS.all'Range loop
               exit when RP.Prec_Sym /= null;
               declare
                  SP : constant Symbol_Access := RP.RHS (I);
               begin
                  if SP.Kind = Multi_Terminal then

                     for J in SP.Sub_Sym.First_Index .. SP.Sub_Sym.Last_Index loop
                        if SP.Sub_Sym (J).Prec >= 0 then
                           RP.Prec_Sym := SP.Sub_Sym (J);
                           exit;
                        end if;
                     end loop;

                  elsif SP.Prec >= 0 then
                     RP.Prec_Sym := RP.RHS (I);
                  end if;
               end;
            end loop;
         end if;
         RP := RP.Next;
      end loop;
   end Find_Rule_Precedences;


   procedure Find_First_Sets (Lemon : in out Lime.Lemon_Record)
   is
      use Rules;
      use Symbols;

      I_Copy   : Integer;
      RP       : Rule_Access;
      Progress : Boolean;
   begin
      Symbols.Set_Lambda_False_And_Set_Firstset (First => Natural (Lemon.N_Terminal),
                                                 Last  => Natural (Lemon.N_Symbol - 1));
--        for I in 0 .. Lemon.N_Symbol - 1 loop
--           Lemon.Symbols (I).lambda := False;
--        end loop;

--        for I in Lemon.N_Terminal .. Lemon.N_Symbol - 1 loop
--           Lemon.Symbols (I).firstset := SetNew (void);
--        end loop;

      --  First compute all lambdas
      loop
         Progress := False;
         RP := Lemon.Rule;
         loop
            exit when RP = null;

            if RP.LHS.Lambda then
               goto Continue;
            end if;

            for I in RP.RHS'Range loop
               I_Copy := I;
               declare
                  SP : constant Symbol_Access := RP.RHS (I);
               begin
                  pragma Assert (SP.Kind = Non_Terminal or SP.Lambda = False);
                  exit when SP.Lambda = False;
               end;
            end loop;

            if I_Copy = RP.RHS'Last then
               RP.LHS.Lambda := True;
               Progress := True;
            end if;

            RP := RP.Next;
         end loop;
         exit when not Progress;
         <<Continue>>
         null;
      end loop;

      --  Now compute all first sets
      loop
         declare
            S1 : LHS_Access;
            S2 : Symbol_Access;
         begin
            Progress := False;
            RP := Lemon.Rule;
            loop
               exit when RP = null;
               S1 := RP.LHS;

               for I in RP.RHS'Range loop
                  S2 := RP.RHS (I);

                  if S2.Kind = Terminal then
                     if Sets.Set_Add (S1.First_Set, Natural (S2.Index)) then
                        Progress := True;
                     end if;
                     exit;

                  elsif S2.Kind = Multi_Terminal then
                     for J in S2.Sub_Sym.First_Index .. S2.Sub_Sym.Last_Index loop
                        if
                          Sets.Set_Add (S1.First_Set,
                                        Natural (S2.Sub_Sym (J).Index))
                        then
                           Progress := True;
                        end if;
                     end loop;
                     exit;

                  elsif Symbol_Access (S1) = S2 then
                     exit when S1.Lambda = False;

                  else
                     if Sets.Set_Union (S1.First_Set, S2.First_Set) then
                        Progress := True;
                     end if;
                     exit when S2.Lambda = False;

                  end if;
               end loop;
               RP := RP.Next;
            end loop;
         end;
         exit when not Progress;

      end loop;
   end Find_First_Sets;


   procedure Find_States
     (Lemon : in out Lime.Lemon_Record)
   is
      use Ada.Strings.Unbounded;
      use Lemon_Bind;
      use Symbols;
      use Rules;

      Lemp : Lime.Lemon_Record renames Lemon;
      SP : Symbol_Access;
      RP : Rule_Access;
   begin
      Configlist_Init;

      --  Find the start symbol
      --  lime_partial_database_dump_c ();
      --  lime_partial_database_dump_ada ();

      if Lemp.Names.Start /= "" then
         SP := Find (To_String (Lemp.Names.Start));
         if SP = null then
            Errors.Error_Plain
              (File_Name   => Lemp.File_Name,
               Line_Number => 0,
               Text        =>
                 "The specified start symbol '%1' Start is not in a nonterminal " &
                 "of the grammar.  '%2' will be used as the start symbol instead.",
               Arguments   => (1 => Lemp.Names.Start,
                               2 => To_Unbounded_String (From_Key (Lemp.Start_Rule.LHS.all.Name)))
              );
            Lemp.Error_Cnt := Lemp.Error_Cnt + 1;
            SP := Symbol_Access (Lemp.Start_Rule.LHS);
         end if;
      else
         SP := Symbol_Access (Lemp.Start_Rule.LHS);
      end if;

      --  Make sure the start symbol doesn't occur on the right-hand side of
      --  any rule.  Report an error if it does.  (YACC would generate a new
      --  start symbol in this case.)
      RP := Lemp.Rule;
      loop
         exit when RP = null;
         for I in RP.RHS'Range loop
            if RP.RHS (I) = SP then   --  FIX ME:  Deal with multiterminals XXX
               Errors.Error_Plain
                 (File_Name   => Lemp.File_Name,
                  Line_Number => 0,
                  Text        =>
                    "The start symbol '%1' occurs on the right-hand " &
                    "side of a rule. This will result in a parser which " &
                    "does not work properly.",
                  Arguments   => (1 => To_Unbounded_String (From_Key (SP.Name)))
                 );
               Lemp.Error_Cnt := Lemp.Error_Cnt + 1;
            end if;
         end loop;
         RP := RP.Next;
      end loop;

      --  The basis configuration set for the first state
      --  is all rules which have the start symbol as their
      --  left-hand side
      RP := Rule_Access (SP.Rule);
      loop
         exit when RP = null;
         declare
            Dummy   : Boolean;
            New_CFP : Configs.Config_Access;
         begin
            RP.LHS_Start := True;
            New_CFP := Configlist_Add_Basis (RP, 0);
            Dummy := Sets.Set_Add (New_CFP.Follow_Set, 0);
         end;
         RP := RP.Next_LHS;
      end loop;

      --  Compute the first state.  All other states will be
      --  computed automatically during the computation of the first one.
      --  The returned pointer to the first state is not used. */
      Get_State (Lemp);

   end Find_States;


end Builds;