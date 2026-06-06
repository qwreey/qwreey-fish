#!/usr/bin/env perl
use strict;
use warnings;

my $file = shift @ARGV;
die "읽을 파일 이름을 같이 넘겨줘~\n" unless defined $file;

local $/ = undef;
open my $fh, '<', $file or die "앗, 파일($file)을 열 수 없어 ㅠㅠ: $!\n";
my $content = <$fh>;
close $fh;

# 함수를 빼고 남은 부분(leftover)을 저장할 변수에 원본 내용 복사!
my $leftover = $content;

while ($content =~ /(^\s*function\s+([^\s]+).*?^end\b)/gms) {
    my $full_func = $1;
    my $fnname = $2;

    my $out_filename = "$fnname.fish";
    open my $out_fh, '>', $out_filename or die "앗! 파일 생성 실패!: $!\n";
    print $out_fh "$full_func\n";
    close $out_fh;

    print "$out_filename 예쁘게 분리 완료!\n";
}

# 2. leftover에서 함수 부분만 싹 지우기 (치환)
$leftover =~ s/(^\s*function\s+[^\s]+.*?^end\b)//gms;

# 함수가 빠져나간 자리에 남은 빈 줄(줄바꿈) 대충 정리~
$leftover =~ s/\n{3,}/\n\n/g; 
$leftover =~ s/^\s+|\s+$//g;

# 3. leftover.fish 에 남은 내용 저장하기
open my $left_fh, '>', 'leftover.fish' or die "leftover.fish 만들 수 없어!: $!\n";
print $left_fh "$leftover\n";
close $left_fh;

print "나머지 코드들은 leftover.fish 에 다 모아뒀어!\n";