--
--
--

with Sessions;
with States;

package Builds is

   use Sessions;

   procedure Find_Rule_Precedences (Session : in out Session_Type);
   --  Find a precedence symbol of every rule in the grammar.
   --
   --  Those rules which have a precedence symbol coded in the input
   --  grammar using the "[symbol]" construct will already have the
   --  rp->precsym field filled.  Other rules take as their precedence
   --  symbol the first RHS symbol with a defined precedence.  If there
   --  are not RHS symbols with a defined precedence, the precedence
   --  symbol field is left blank.


   procedure Find_First_Sets (Session : in out Session_Type);
   --  Find all nonterminals which will generate the empty string.
   --  Then go back and compute the first sets of every nonterminal.
   --  The first set is the set of all terminal symbols which can begin
   --  a string generated by that nonterminal.


   procedure Find_States (Session : in out Session_Type);
   --  Compute all LR(0) states for the grammar.  Links are added to
   --  between some states so that the LR(1) follow sets can be
   --  computed later.

   procedure Find_Links (Session : in Session_Type);
   --  Construct the propagation Links

   procedure Find_Follow_Sets (Session : in Session_Type);
   --  Compute all followsets.
   --  A followset is the set of all symbols which can come immediately
   --  after a configuration.

   procedure Find_Actions (Session : in out Session_Type);
   --  Compute the reduce actions, and resolve Conflicts.


   function Get_State (Session : in out Sessions.Session_Type)
                      return States.State_Access;
   procedure Get_First_State (Session : in out Sessions.Session_Type);
   --  Compute all LR(0) states for the grammar.  Links
   --  are added to between some states so that the LR(1) follow sets
   --  can be computed later.


   procedure Build_Shifts (Session : in out Session_Type;
                           State   : in out States.State_Record);
   --  Construct all successor states to the given state.  A "successor"
   --  state is any state which can be reached by a shift action.

private

   pragma Export (C, Find_States,      "cherry_find_states");
   pragma Import (C, Find_Links,       "lemon_find_links");
   pragma Import (C, Find_Follow_Sets, "lemon_find_follow_sets");

end Builds;
