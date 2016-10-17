=begin comment
  Author José Albert Cruz Almaguer <jalbertcruz@gmail.com>
  Copyright 2016 by José Albert Cruz Almaguer.

  This program is licensed to you under the terms of version 3 of the
  GNU Affero General Public License. This program is distributed WITHOUT
  ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING THOSE OF NON-INFRINGEMENT,
  MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. Please refer to the
  AGPL (http://www.gnu.org/licenses/agpl-3.0.txt) for more details.
=end comment

unit module Ch3::Letlang;

grammar LET-lang-Grammar is export {
  token expression:sym<number> { \d+ }
  token expression:sym<identifier> { \w+ }

  rule TOP { ^ <expression> }
  # rule expression { [ <number> | <diff-exp>   | #`(<is-zero-exp> | )   <if-exp> | <identifier> | <let-exp>       ] }

  proto rule expression {*}
  rule expression:sym<diff-exp> { '-' '(' <exp1=.expression> ',' <exp2=.expression> ')' }
  # rule is-zero-exp { 'zero?' '(' <expression> ')' }
  rule expression:sym<if-exp> { 'if' <cond=.expression> 'then' <exp1=.expression> 'else' <exp2=.expression> }
  rule expression:sym<let-exp> { 'let' <identifier=.expression:sym<identifier>> '=' <exp1=.expression> 'in' <exp2=.expression> }

}

class AST::Exp {}
class AST::Number is AST::Exp {
  has Int $.val;
}
class AST::Diff-exp is AST::Exp {
  has AST::Exp $.exp1;
  has AST::Exp $.exp2;
}
class AST::If-exp is AST::Exp {
  has AST::Exp $.cond;
  has AST::Exp $.exp1;
  has AST::Exp $.exp2;
}
class AST::Id is AST::Exp {
  has Str $.val;
}
class AST::Let-exp is AST::Exp {
  has AST::Id $.id;
  has AST::Exp $.exp1;
  has AST::Exp $.exp2;
}

class LET-lang-AST is export {
  method expression:sym<number> ($/) {
    make AST::Number.new(val => +$/)
  }
  method expression:sym<identifier> ($/) {
    make AST::Id.new(val => ~$/)
  }

  method TOP ($/) {
    make $<expression>.made;
  }

  method expression:sym<diff-exp> ($/) {
    make AST::Diff-exp.new(exp1 => $<exp1>.made, exp2 => $<exp2>.made)
  }
  # method is-zero-exp($/) {  }
  method expression:sym<if-exp> ($/) {
    make AST::If-exp.new(cond => $<cond>.made, exp1 => $<exp1>.made, exp2 => $<exp2>.made)
  }
  method expression:sym<let-exp> ($/) {
    make AST::Let-exp.new(id => $<identifier>.made, exp1 => $<exp1>.made, exp2 => $<exp2>.made)
  }
}

class Machine is export {
    has %.environment;

    method eval-num(AST::Number $e){
      $e.val
    }

    method eval-diff-exp(AST::Diff-exp $e){
      my $e1 = self.eval($e.exp1);
      my $e2 = self.eval($e.exp2);
      AST::Number.new(val => $e1 - $e2)
    }

    method eval-if-exp(AST::If-exp $e){
      do if self.eval($e.cond) {
        self.eval($e.exp1);
      } else {
        self.eval($e.exp2);
      }
    }

    method eval-id(AST::Id $e){
      %.environment{$e.val}
    }

    method eval-let-exp(AST::Let-exp $e){
      my $v1 = self.eval($e.exp1);
      %.environment{$e.id.val} = $v1;
      AST::Number.new( val => self.eval($e.exp2) )
    }

    method eval($e) {
      given $e {
          when AST::Number {
              self.eval-num($e)
          }
          when AST::Diff-exp {
              self.eval(self.eval-diff-exp($e))
          }
          when AST::If-exp {
              self.eval(self.eval-if-exp($e))
          }
          when AST::Id {
              self.eval-id($e)
          }
          when AST::Let-exp {
              self.eval(self.eval-let-exp($e))
          }
          default { 0 }
      }

    }
}
