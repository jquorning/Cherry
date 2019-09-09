--
--  The author disclaims copyright to this source code.  In place of
--  a legal notice, here is a blessing:
--
--    May you do good and not evil.
--    May you find forgiveness for yourself and forgive others.
--    May you share freely, not taking more than you give.
--

with Ada.Text_IO;
with Ada.Directories;

with Setup;
with Auxiliary;

package body Generate_Ada is


   procedure Open_Template
     (Context       : in out Context_Type;
      File_Name     : in out Ada.Strings.Unbounded.Unbounded_String;
      User_Template : in     String;
      Error_Count   : in out Integer)
   is
      use Ada.Strings.Unbounded;
      use Ada.Text_IO;
      Default_Template : String renames Setup.Default_Template_Ada;
      Template_Name    : Unbounded_String;
   begin
      Ada.Text_IO.Put_Line ("### AOT 1");

      --  First, see if user specified a template filename on the command line.
      if User_Template /= "" then

         --  Eksisterer den angivede template fil
         if not Ada.Directories.Exists (User_Template) then
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               "Can not find the parser driver template file '" & User_Template & "'.");
            Error_Count   := Error_Count + 1;
            Template_Name := Null_Unbounded_String;
            return;
         end if;

         --  Can User_Template open.
         begin
            Open (Context.File_Template, In_File, User_Template);

         exception
            when others =>
               --  No it could not open User_Template.
               Put_Line
                 (Standard_Error,
                  "Can not open the template file '" & User_Template & "'.");
               Error_Count := Error_Count + 1;
               Template_Name := Null_Unbounded_String;
               return;
         end;
         return;         --  User template open with success.
      end if;

      --  No user template.
      declare
--         use Ada.Strings.Fixed;
         Point : constant Natural := Index (File_Name, ".");
         Buf   : Unbounded_String;
      begin
         if Point = 0 then
            Buf := File_Name & ".lt";
--            Buf (Buf_0'Range) := Buf_0;  Last := Buf_0'Last;
         else
            Buf := File_Name & ".lt";
--            Buf (Buf_X'Range) := Buf_X;  Last := Buf_X'Last;
         end if;

         if Ada.Directories.Exists (To_String (Buf)) then
            Ada.Text_IO.Put_Line ("### 3-1");
            Template_Name := Buf;
         elsif Ada.Directories.Exists (Default_Template) then
            Ada.Text_IO.Put_Line ("### 3-2");
            Template_Name := To_Unbounded_String (Default_Template);
         else
            Ada.Text_IO.Put_Line ("### 3-3");
            --  Template_Name := Pathsearch (Lemp.Argv0, Templatename, 0);
         end if;
      end;

      Ada.Text_IO.Put_Line ("### 3-4");
      if Template_Name = Null_Unbounded_String then
         Ada.Text_IO.Put_Line ("### 3-5");
         Put_Line
           (Standard_Error,
            "Can not find then parser driver template file '" & To_String (Template_Name) & "'.");
         Error_Count := Error_Count + 1;
         return;
      end if;

      begin
         Ada.Text_IO.Put_Line ("### 6-1");
         Open (Context.File_Template,
               In_File, To_String (Template_Name));
         Ada.Text_IO.Put_Line ("### 6-2");

      exception
         when others =>
            Ada.Text_IO.Put_Line ("### 3-6");
            Put_Line
              (Standard_Error,
               "Can not open then template file '" & To_String (Template_Name) & ".");
            Error_Count := Error_Count + 1;
            return;
      end;

--      Template_Name := New_String (Tem
   end Open_Template;


   procedure Generate_Spec
     (Context   : in out Context_Type;
      Base_Name : in     String;
      Module    : in     String;
      Prefix    : in     String;
      First     : in     Integer;
      Last      : in     Integer)
   is
      pragma Unreferenced (Context);
      use Auxiliary, Ada.Text_IO;
--      Module : constant String := Auxiliary.To_Ada_Symbol (Base_Name);
      File   : File_Type;
   begin
      Put_Line ("GENERATE_SPEC");
      Recreate (File, Out_File, Base_Name & ".ads");
      Set_Output (File);
      --  Prolog
      Put_Line ("--");
      Put_Line ("--  Generated by cherrylemon");
      Put_Line ("--");
      New_Line;
      Put_Line ("package " & Module & " is");

      Set_Output (File);
      for I in First .. Last loop
         declare
            Symbol : constant String := Prefix; --  & Lime.Get_Token (I);
         begin
            Set_Col (File, 4); --  ..Put (File, "   ");
            Put (File, Symbol);
            Set_Col (File, 20);
            Put (File, " : constant Token_Type := ");
            Put (File, Integer'Image (I));
            Put (File, ";");
            New_Line (File);
         end;
      end loop;

      --  Epilog
      Put_Line (File, "end " & Module & ";");

      Close (File);
      Set_Output (Standard_Output);
   end Generate_Spec;


end Generate_Ada;
