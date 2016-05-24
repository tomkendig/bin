package Hello;
sub new() { bless {} }
sub Hello() { print "Hello, world!p\n" }
package main;
my $hello = new Hello;
$hello->Hello();
