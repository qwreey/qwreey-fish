#!/usr/bin/env perl
# 몰루 이런 스크립트는 gemini 가 만듦
# fish 파일 입력받으면 안 toplevel 함수들을 모두 분리해서
# fnname.fish 들로 분리하고 toplevel 에 그냥 남아있는 코드들은 leftover.fish 안에 넣어줌

use strict;
use warnings;

my $file = shift @ARGV;
die "읽을 파일 이름을 같이 넘기세요\n" unless defined $file;

local $/ = undef;
open my $fh, '<', $file or die "파일($file)을 열 수 없습니다: $!\n";
my $content = <$fh>;
close $fh;

# 함수를 빼고 남은 부분(leftover)을 저장할 변수에 원본 내용 복사
my $leftover = $content;

while ($content =~ /(^\s*function\s+([^\s]+).*?^end\b)/gms) {
    my $full_func = $1;
    my $fnname = $2;

    my $out_filename = "$fnname.fish";
    open my $out_fh, '>', $out_filename or die "파일 생성 실패!: $!\n";
    print $out_fh "$full_func\n";
    close $out_fh;

    print "$out_filename 분리 완료!\n";
}

# 2. leftover에서 함수 부분만 싹 지우기 (치환)
$leftover =~ s/(^\s*function\s+[^\s]+.*?^end\b)//gms;

# 함수가 빠져나간 자리에 남은 빈 줄(줄바꿈) 대충 정리
$leftover =~ s/\n{3,}/\n\n/g; 
$leftover =~ s/^\s+|\s+$//g;

# 3. leftover.fish 에 남은 내용 저장하기
open my $left_fh, '>', 'leftover.fish' or die "leftover.fish 만들 수 없습니다: $!\n";
print $left_fh "$leftover\n";
close $left_fh;

