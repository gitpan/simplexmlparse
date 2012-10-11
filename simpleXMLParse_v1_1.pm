package simpleXMLParse;

# Perl Module: simpleXMLParse
# Author: Daniel Edward Graham
# Copyright (c) Daniel Edward Graham 10/2012
# Date: 10/10/2012
# License: LGPL 3.0
# 

use Carp;
use strict;

sub new {
    my $class = shift;
    if ( @_ != 1 ) {
        croak "Invalid usage (new)\n";
    }
    my $inputfile = shift;
    my $altstyle = 0;
    my $fn;
    if ( ref($inputfile) eq "HASH" ) {
        $fn = $inputfile->{"input"};
        $altstyle = 1 if ($inputfile->{"style"} eq '2');
    }
    my $self = {};
    $self->{"xml"}  = undef;
    $self->{"data"} = undef;
    open( INFILE, "$fn" ) or croak "Unable to process [$fn]\n";
    $self->{"xml"} = join '', <INFILE>;
    close(INFILE);
    $self->{"xml"} =~ s/\<\?[^\>]*?\?\>//g;
    $self->{"xml"} =~ s/\<\!\-\-[^\>]*?\-\-\>//g;
    $self->{"data"} = _ParseXML( $self->{"xml"} );
    my $ret = bless $self;
    if ($altstyle) {
        warn "alt style";
        $ret->_convertToStyle();
    }
    return $ret;
}

sub data {
    my $self = shift;
    return $self->{"data"};
}

sub _convertToStyle {
    my $self = shift;
    my @recursearr = ($self->{"data"});
    while (my $i = pop @recursearr) {
        if (ref($i) eq "HASH") {
            foreach my $j (keys %$i) {
                if ($j =~ /^(.*?)\_(.*?)\_([0-9]+)\_attr$/) {
                    my ($attrnm, $tagnm, $cnt) = ($1, $2, $3);
                    my $n = undef;
                    if (ref($i->{$tagnm}) eq "ARRAY") {
                        my $hold;
                        if (ref($i->{$tagnm}->[$cnt]) eq '') {
                            $hold = $i->{$tagnm}->[$cnt];
                            $i->{$tagnm}->[$cnt] = { };
                            if ($hold !~ /^\s*$/ ) {
                                $i->{$tagnm}->[$cnt]->{VALUE} = $hold;
                            }
                        }      
                        while (defined($i->{$tagnm}->[$cnt]->{$attrnm.$n})) {
                            $n++;
                        }
                        $i->{$tagnm}->[$cnt]->{$attrnm.$n} = $i->{$j};
                     } else {
                         if (ref($i->{$tagnm}) eq "HASH") { 
                             my $n = undef;
                             while (defined($i->{$tagnm}->{$attrnm.$n})) {
                                $n++;
                             }
                             $i->{$tagnm}->{$attrnm.$n} = $i->{$j};
                         } else {
                             my $hold;
                             $hold = $i->{$tagnm};
                             $i->{$tagnm} = { };
                             if ($hold !~ /^\s*$/) {
                                 $i->{$tagnm}->{VALUE} = $hold;
                             }
                             $i->{$tagnm}->{$attrnm} = $i->{$j};
                         }
                     }
                     delete $i->{$j};
               } else {
                   push @recursearr, $i->{$j};
               }
           }
        } else {
            if (ref($i) eq "ARRAY") {
                foreach my $j (@$i) {
                    push @recursearr, $j;
                }
            }
       }
   }
}

sub _ParseXML {
    my ($xml) = @_;
    $xml =~ s/\n//g;
    $xml =~ s/\<\!\-\-.*?\-\-\>//g;
    $xml =~ s/\<\?xml.*?\?\>//g;
    my $rethash = ();
    my @retarr;
    my $firsttag = $xml;
    my ( $attr, $innerxml, $xmlfragment );
    $firsttag =~ s/^[\s\n]*\<([^\s\>\n]*).*$/$1/g;
    $firsttag =~ s/\\/\\\\/g;
    $firsttag =~ s/\*/\\\*/g;
    $firsttag =~ s/\{/\\\{/g;
    $firsttag =~ s/\}/\\\}/g;
    $firsttag =~ s/\(/\\\(/g;
    $firsttag =~ s/\)/\\\)/g;
    $firsttag =~ s/\=/\\\=/g;
    $firsttag =~ s/\+/\\\+/g;
    $firsttag =~ s/\[/\\\[/g;
    $firsttag =~ s/\]/\\\]/g;
    $firsttag =~ s/\./\\\./g;
    $firsttag =~ s/\-/\\\-/g;

    if ( $xml =~ /^[\s\n]*\<${firsttag}(\>|\s[^\>]*\>)(.*?)\<\/${firsttag}\>(.*)$/ )
    {
        $attr        = $1;
        $innerxml    = $2;
        $xmlfragment = $3;
        $attr =~ s/\>$//g;
    }
    else {
        return $xml;
    }
    my $ixml = $innerxml;
    while ($ixml =~ /.*?\<${firsttag}(\>|\s[^\>]*\>)(.*?)$/) {
        $ixml = $2;
        $innerxml .= "</${firsttag}>";
        if ($xmlfragment =~ /(.*?)\<\/${firsttag}\>(.*)$/) {
            $innerxml .= $1;
            $xmlfragment = $2;
        } else {
            die "Invalid XML";
        }
    }        
    my $nextparse = _ParseXML($innerxml);
    $rethash->{"$firsttag"} = $nextparse;
    my @attrarr;
    while ( $attr =~ s/^[\s\n]*([^\s\=\n]+)\=[\"\'](.*?)[\"\'](.*)$/$3/g ) {
        push @attrarr, $1;
        push @attrarr, $2;
    }
    my $attrcnt = 0;
    while ( my $val = shift(@attrarr) ) {
        $rethash->{ "$val" . "_${firsttag}_" . $attrcnt . "_attr" } = shift(@attrarr);
    }
    my $retflag = 0;
    my ( $xmlfragment1, $xmlfragment2 );
    my %attrhash;
    $attrcnt++;
    while ( $xmlfragment =~
        /^(.*?)\<${firsttag}(\>|\s[^\>]*\>)(.*?)\<\/${firsttag}\>(.*)$/ )
    {
        if ( !$retflag ) {
            push @retarr, $nextparse;
        }
        $retflag      = 1;
        $xmlfragment1 = $1;
        $attr         = $2;
        $innerxml     = $3;
        $xmlfragment2 = $4;
        $attr =~ s/\>$//g;
        my %opening = ( );
        my %closing = ( );
        my $frag = $xmlfragment1;
        while ($frag =~ /^(.*?)\<([^\s\n]+).*?\>(.*)$/) {
            my $tg = $2;
            $frag = $3;
            $opening{$tg}++;
        }
        my $frag = $xmlfragment1;
        while ($frag =~ /^(.*?)\<\/([^\s\n]+)\>(.*)$/) {
            my $tg = $2;
            $frag = $3;
            $closing{$tg}++;
        }
        my $flag = 0;
        foreach my $k (keys %opening) {
            if ($opening{$k} > $closing{$k}) {
                $xmlfragment = $xmlfragment1 . "<${firsttag}0x0 ${attr}>${innerxml}</${firsttag}0x0>". $xmlfragment2;
                $flag = 1;
                last;
            }
        }
        next if ($flag);
        $xmlfragment  = $xmlfragment1 . $xmlfragment2;
        my $ixml = $innerxml;
        while ($ixml =~ /.*?\<${firsttag}(\>|\s[^\>]*\>)(.*?)$/) {
            $ixml = $2;
            $innerxml .= "</${firsttag}>";
            if ($xmlfragment2 =~ /(.*?)\<\/${firsttag}\>(.*)$/) {
                $innerxml .= $1;
                $xmlfragment2 = $2;
            } else {
                die "Invalid XML";
            }
        }        
        while ( $attr =~ s/^[\s\n]*([^\s\=\n]+)\=[\"\'](.*?)[\"\'](.*)$/$3/g ) {
            push @attrarr, $1;
            push @attrarr, $2;
        }
        while ( my $val = shift(@attrarr) ) {
#            if (defined($rethash->{"$val" . "_$firsttag" . "_attr" })) {
#                $rethash->{ "$val" . "_${firsttag}_" . ++$attrhash{"$val" . "_$firsttag" . "_attr"} . "_attr" } = shift(@attrarr);
                $rethash->{ "$val" . "_${firsttag}_" . $attrcnt . "_attr" } = shift(@attrarr);
#            } else { 
#                $rethash->{ "$val" . "_$firsttag" . "_attr" } = shift(@attrarr);
#            }
        }
        $attrcnt++;
        $nextparse    = _ParseXML($innerxml);
        push @retarr, $nextparse;
    }
    if (@retarr) {
        $rethash->{"$firsttag"} = \@retarr;
    }
    $xmlfragment =~ s/${firsttag}0x0/${firsttag}/g;
    my $remainderparse = _ParseXML($xmlfragment);
    my $attrcnt;
    my $attrfrag;
    if ( ref($remainderparse) eq "HASH" ) {
        foreach ( keys %{$remainderparse} ) {
            $rethash->{"$_"} = $remainderparse->{"$_"};
        }
    }
    if ( keys %{$rethash} ) {
        return $rethash;
    }
    else {
        return undef;
    }
}

1;