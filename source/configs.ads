--
--  The author disclaims copyright to this source code.  In place of
--  a legal notice, here is a blessing:
--
--    May you do good and not evil.
--    May you find forgiveness for yourself and forgive others.
--    May you share freely, not taking more than you give.
--

with Rules;
with Sets;
with Prop_Links;
limited with States;

package Configs is

   --  A configuration is a production rule of the grammar together with
   --  a mark (dot) showing how much of that rule has been processed so far.
   --  Configurations also contain a follow-set which is a list of terminal
   --  symbols which are allowed to immediately follow the end of the rule.
   --  Every configuration is recorded as an instance of the following:
   type Config_Status is (Complete, Incomplete);

   type Config_Record;
   type Config_Access is access all Config_Record;

   --  A followset propagation link indicates that the contents of one
   --  configuration followset should be propagated to another whenever
   --  the first changes.   pragma Convention (C_Pass_By_Copy, State_Record);
--   type Plink_Record;
--   type Plink_Access is access all Plink_Record;

--   type Plink_Record is
--      record
--         Config : access Configs.Config_Record; --  The configuration to which linked
--         Next   : Plink_Access;                 --  The next propagate link
--      end record;
--   pragma Convention (C_Pass_By_Copy, Plink_Record);  -- lemon.h:188

   type Config_Record is record
      Rule        : Rules.Rule_Access;         --  The rule upon which the configuration is based
      Dot         : Integer;                   --  The parse point

      Follow_Set  : Sets.Set_Type;
      --  FWS, Follow-set for this configuration only

      Forward_PL  : Prop_Links.List;                --  forward propagation links
      Backward_PL : Prop_Links.List;                --  Follow-set backwards propagation links
      State       : access States.State_Record;  --  Pointer to state which contains this
      Status      : Config_Status;               --  used during followset and shift computations
      Next        : Config_Access;               --  Next configuration in the state
      Basis       : Config_Access;               --  bp, The next basis configuration
   end record;
--   pragma Convention (C_Pass_By_Copy, Config_Record);

end Configs;
