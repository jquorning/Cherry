--
--  The author disclaims copyright to this source code.  In place of
--  a legal notice, here is a blessing:
--
--    May you do good and not evil.
--    May you find forgiveness for yourself and forgive others.
--    May you share freely, not taking more than you give.
--

with Ada.Exceptions;

package Exceptions is

   procedure Put_Message
     (Occurrence : in Ada.Exceptions.Exception_Occurrence);

end Exceptions;
