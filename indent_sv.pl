#!/usr/bin/env perl
use Getopt::Long;



GetOptions("file=s"=>\$sv_need_indent,
           "sn=i"  =>\$space_num,
           "debug" =>\$debug,
           "help"  => sub {help_info()}
          ) or help_info();

if ( not defined $sv_need_indent){
  print "Please specify the file yo want to indent\n";
  help_info();
  exit;
}

$indent_cnt = 0;
@inc_keywords=qw/begin case casex casez class    clocking    config    function    generate    covergroup interface    module    package    primitive    program    property    specify    table    task    fork randcase/;
@dec_keywords=qw/end   endcase          endclass endclocking endconfig endfunction endgenerate endgroup   endinterface endmodule endpackage endprimitive endprogram endproperty endspecify endtable endtask join join_none join_any/;
@exclude_keywords = ('\/\*.*\*\/','".*"','\'.*\'','\/\/.*','\(.*\)','extern\s+.*?task','import\s+.*?function','export\s+.*?function','extern\s+.*?function','\bpure\s+virtual\s+.*?task','\bpure\s+virtual\s+.*?function','disable\s+fork','virtual\s+interface','typedef\s+class','wait\s+fork\b');

if ( not defined $space_num) {
  $space_num = 2;
}

if ($space_num < 0) {
  print "space_num should not be less than 0!\n";
  exit;
}
$pattern_space = " "x$space_num;

open ($need_indent_file, "<$sv_need_indent") || die;
open ($indented_file_1st, ">$sv_need_indent.1st") || die;

$line_cnt = 0;
$get_comment = 0;
while(<$need_indent_file>){
  chomp;
  $line     = &trim($_);
  $org_line = $line;

  if ($get_comment) {
    if ($line !~ /\*\//) {
      print $indented_file_1st $spaces.$org_line."\n";
      next;
    }
  }
  foreach my $ex_pattern (@exclude_keywords) {
    $line =~ s/$ex_pattern/ /g;
  }
  if ($line =~ /(.*?\*\/)(.*?)(\/\*.*)/) {
    $get_comment = 1;
    $line = $2;
  }elsif ($line =~ /(.*?)(\/\*.*)/) {
    $line = $1;
    $get_comment = 1;
  }elsif($line =~ /(.*?\*\/)(.*)/){
    $line = $2;
    $get_comment = 0;
  }

  @elems = split(/\s+/,$line);

  $line_kw_cnt = 0;
  foreach$to_match(@elems){
    foreach(@inc_keywords){
      if($to_match =~ /\b$_\b/){
        $line_kw_cnt++;
      }
    }
    foreach(@dec_keywords){
      if($to_match =~ /\b$_\b/){
        $line_kw_cnt--;
      }
    }
  }

  if ($line_kw_cnt < 0) {
    $indent_cnt += $line_kw_cnt;
    $spaces = ${pattern_space}x$indent_cnt;
    #$spaces =~ s/^$pattern_space// if($org_line =~ /^`ifndef|^`ifdef|^`else|^`elsif|^`endif/);
    print $indented_file_1st $spaces.$org_line."\n";

  }elsif($line_kw_cnt>0){
    $spaces = ${pattern_space}x$indent_cnt;
    #$spaces =~ s/^$pattern_space// if($org_line =~ /^`ifndef|^`ifdef|^`else|^`elsif|^`endif/);
    print $indented_file_1st $spaces.$org_line."\n";
    $indent_cnt += $line_kw_cnt;
  }else{
    $spaces = ${pattern_space}x$indent_cnt;
    #$spaces =~ s/^$pattern_space// if($org_line =~ /^`ifndef|^`ifdef|^`else|^`elsif|^`endif|^end/);
    print $indented_file_1st $spaces.$org_line."\n";
  }

  if ($indent_cnt < 0) {
    print "ERROR!!!!! line: $line_cnt $sv_need_indent\n";
    exit;
  }
  $line_cnt++;
}
close($need_indent_file);
close($indented_file_1st);
if ($indent_cnt != 0) {
  print "$sv_need_indent \n";
}

open ($indented_file_1st, "<$sv_need_indent.1st") || die;
open ($indented_file_2nd, ">$sv_need_indent.2nd") || die;

$get_if_not_begin = 0;

while(<$indented_file_1st>){

  $line = $_;
  s/\/\/.*//g;
  if(/\bif\b|\belse\b/ and !/\bbegin\b/ and !/;/){
    $get_if_not_begin = 1;
    print $indented_file_2nd $line;
    next;
  }

  if($get_if_not_begin == 1){

    if(/^\s*$/ or /^\s*\/\// or /^\s*\/\*/){
      print $indented_file_2nd $line;
      next;
    }

    $get_if_not_begin = 0;
    if (!/\bbegin\b/) {
      print $indented_file_2nd " "x$space_num.$line;
    }else {
      print $indented_file_2nd $line;
    }

  }else{
    print $indented_file_2nd $line;
  }
}

close($indented_file_2nd);
close($indented_file_1st);

open ($indented_file_2nd, "<$sv_need_indent.2nd") || die;
open ($indented_file_3rd, ">$sv_need_indent.3rd") || die;

$get_left_curly_brace = 0;
while(<$indented_file_2nd>){
  $line = $_;
  s/\/\/.*//g;
  if(/\{/ and !/\}/ and not /with\s*\{/){
    $get_left_curly_brace = 1;
    s/(.*\{).*/$1/;
    chomp;
    $left_curly_brace_space = length($_);
    $left_curly_brace_space += $space_num;
    print $indented_file_3rd $line;
    next;
  }
  if($get_left_curly_brace == 1){
    $line =~ s/^\s*//;
    if(/\}/ and not /\{/){
      $get_left_curly_brace = 0;
      if (/^\s*\}/) {
        $left_curly_brace_space = $left_curly_brace_space - $space_num - 1;
        print $indented_file_3rd " "x$left_curly_brace_space.$line;
      }else{
        print $indented_file_3rd " "x$left_curly_brace_space.$line;
        $left_curly_brace_space = $left_curly_brace_space - $space_num - 1;
      }
    }else{
      print $indented_file_3rd " "x$left_curly_brace_space.$line;
    }
    if($left_curly_brace_space < 0) {
      print "left_curly_brace_space should not be less than 0!\n";
      exit;
    }
  }else{
    print $indented_file_3rd $line;
  }
}

close($indented_file_2nd);
close($indented_file_3rd);

if(!defined $debug){
  unlink $sv_need_indent;
  unlink "$sv_need_indent.1st";
  unlink "$sv_need_indent.2nd";
  rename "$sv_need_indent.3rd",$sv_need_indent;
}

sub trim{
  $aug = @_[0];
  $aug =~ s/^\s+|\s+$//g;
  return $aug;
}

sub help_info{
  print 'Usage : $ indent_sv.pl -f <file_name>'."\n";
  print 'Usage : $ indent_sv.pl -f <file_name> -sn <number>'." #default indent = 2 space, you can use -sn to specify the number.\n";
}
