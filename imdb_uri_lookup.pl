# 
# Spotify Irssi plugin 
# Decode and print information from Spotify URIs 
# 

# 
# Changes 
# 0.1 First version!

use strict; 
use Irssi; 
use JSON;
use feature qw(switch say);

use Irssi::Irc; 
use LWP::UserAgent; 
use vars qw($VERSION %IRSSI);

$VERSION = '0.1'; 
%IRSSI = ( 
    authors     => 'Fredrik Karlsson', 
    contact     => 'fkarlsson@gmail.com', 

    name        => 'imdb_uri_lookup', 
    description => 'Lookup IMDB URIs and output info to proper window.', 
    license     => '', 
    url         => '', 
); 

sub imdburi_public { 
    my ($server, $data, $nick, $mask, $target) = @_; 
    my $retval = spotifyuri_get($data); 
    my $win = $server->window_item_find($target); 
    Irssi::signal_continue(@_);

    if ($win) { 
        $win->print("%_Spotify:%_ $retval", MSGLEVEL_CRAP) if $retval; 
    } else { 
        Irssi::print("%_Spotify:%_ $retval") if $retval; 
    } 
} 
sub imdburi_private { 
    my ($server, $data, $nick, $mask) = @_; 
    my $retval = spotifyuri_get($data); 
    my $win = Irssi::window_find_name('(msgs)'); 
    Irssi::signal_continue(@_);

    if ($win) { 
        $win->print("%_Spotify:%_ $retval", MSGLEVEL_CRAP) if $retval; 
    } else { 
        Irssi::print("%_Spotify:%_ $retval") if $retval; 
    } 
} 
sub imdburi_parse { 
    my ($url) = @_; 
    if ($url =~ /(http:\/\/imdb.com\/|http:\/\/www.imdb.com\/)(title)\/tt([0-9]+)\/?/) { 
        return "http://www.imdbapi.com/?i=$3";
    } 
    return 0; 
} 
sub imdburi_get { 
    my ($data) = @_; 

    my $url = imdburi_parse($data); 
    print $url;

    my $ua = LWP::UserAgent->new(env_proxy=>1, keep_alive=>1, timeout=>5); 
    $ua->agent("irssi/$VERSION " . $ua->agent()); 

    my $req = HTTP::Request->new('GET', $url); 
    my $res = $ua->request($req);

    if ($res->is_success()) { 
        my $json = JSON->new->utf8;
        my $json_data = $json->decode($res->content());
        my $result_string = '';

        my $type = $json_data->{info}->{type};
        given ($type) {
            when ('track') {
                my $artists = '';
                foreach my $artist(@{$json_data->{track}->{artists}}) {
                    if ($artists == '') {
                        $artists = $artist->{name};
                    } else {
                        $artists .= ", " . $artist->{name};;
                    }
                }

                $result_string = "$artists - $json_data->{track}->{name} %K[%n$json_data->{track}->{album}->{name}%K]%n";
            }
            when ('album') {
                my $album = $json_data->{album}->{name};
                my $album_year = $json_data->{album}->{released};
                my $artist = $json_data->{album}->{artist};

                $result_string = "$artist - $album %K[%n$album_year%K]%n";
            }
            when ('artist') {
                $result_string = $json_data->{artist}->{name};
            }
            default {
                $result_string = 'Error';
            }
        }

        return $result_string; 
    } 
    return 0; 
} 

Irssi::signal_add_last('message public', 'imdburi_public'); 
Irssi::signal_add_last('message private', 'imdburi_private'); 