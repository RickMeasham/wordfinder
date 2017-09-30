package Wordfinder::Model::FindWords;

=pod
This is the core word finding utility. The approach used here is to pre-cache the word list so we only read it from
disk once. This saves us up to a couple of seconds per request. We then optimise the retrieved list so that we can
find matching words with a single regex on a single pass through the list.

For example, if we have the letters to make 'god' then we also have the letters to make 'dog'. So to optimise this
we will sort the letters and use that as a key. This results in storing { 'dgo' => [ 'dog', 'god' ] }.

Now if our input is 'god' we can do the same and get 'dgo' and thus find both 'dog' and 'god'. However these input
letters will also match 'go' and 'do'. So rather than looking for 'dgo' we need to look for /d?g?o?/. This regular
expression with match 'do', 'dog', 'go' and 'god'.

* * *

PLEASE NOTE: The code challenge suggested using /usr/share/dict/words. However this file contains many lines that
wouldn't normally be considered to be words. There are lines for 'D', 'd', 'O', 'o', 'G' and 'g'. There are also
many lines that contain initialisms and abbreviations (Eg 'AA', 'aa', 'AAA', 'aaa', 'AAAA', 'AAAAAA' are all in there)
which might or might not be suitable for the end user's purpose. Because of this, I've also include SOWPODS in
usr/share/dict/sowpods. This is the Scrabble players dictionary and thus only includes actual English words and doesn't
include proper nouns. The entire results list for 'god' is now "do", "dog", "go", "god" -- and "od" (a hypothetical
power once thought to pervade nature and account for various scientific phenomena)

To switch between the two, change the WORDFILE constant from 'SOWPODS' to 'DICT_WORDS'.

=cut

use strict;
use warnings FATAL => 'all';

use File::Slurp;
use Time::HiRes;

use constant {
    DICT_WORDS => '/usr/share/dict/words',
    SOWPODS    => 'usr/share/dict/sowpods'
};

# Change to SOWPODS to use the official Scrabble dictionary
use constant WORDFILE => SOWPODS;

# This is where we cache our word list. The key is the letters of the word in alphabetic order.
# For example, 'dgo' is the key for both 'dog' and 'god'. The value is the list of words for which
# this key is approprite. This results in:
# { 'dgo' => [ 'dog', 'god' ] }
my %words;

sub new { bless {}, shift }

# init()
#
# Rather than parse the (massive) word list on every request, we'll do it once on init. It's then
# kept in memory and we just need to find matching keys on each request. Outputs the number of words
# and the time taken to load them.
#
# @return   Returns '1' on success
sub init {
    my ($self, $app) = @_;

    my $start = Time::HiRes::time;

    # All words from the dictionary
    my @inputWords = read_file( WORDFILE, chomp => 1 );

    # Only words that only contain alpha chars. As our input doesn't allow other words it's pointless keeping them.
    my @allowedWords = grep { /^[a-z]+$/i } @inputWords;

    foreach my $word (@allowedWords) {
        push( @{ $words{ $self->makeKey($word) } }, $word );
    }

    $app->log->info(sprintf("Loaded %d words (%d keys) in %f seconds.\n",
        scalar @allowedWords,
        scalar keys %words,
        Time::HiRes::time - $start
    ));

    return 1;
}

# makeKey
#
# Returns the letters of a provided word in lowercase alphabetical order. For example, 'God' returns 'dgo'
#
# @param    $input  Word for which we want the key
# @return   $key    The key for the provided word
sub makeKey {
    my ($self, $key) = @_;
    return join( '', sort split //, lc $key );
}

# makeRegex
#
# Returns a regex for a provided word that can be used to match keys in our %words list. The input is first
# sorted in the same manner as the key, but is then interspersed with the '?' regex optional match. This means
# that the 'God' input becomes '^d?g?o?$' which will match our 'dgo' key, but will also match keys like 'go'.
#
# @param    $input  Word for which we want the key
# @return   $key    The key for the provided word
sub makeRegex {
    my ($self, $input) = @_;
    return '^' . join( '', map { $_ . '?' } sort split //, lc $input ) . '$';
}

# findWords
#
# Find keys in our cached list that match the input letters. We do this by turning the input into a regex
# (see makeRegex) and running that against all the keys in our word list
#
# @param    $input  The letters we can use to form words
# @return   @words  A list of words that can be formed usint the input letters
sub find {
    my ($self, $input) = @_;

    my $regex = $self->makeRegex($input);

    my @matchingWords;
    foreach my $key ( keys %words ) {
        if ( $key =~ /$regex/ ) {
            push( @matchingWords, @{ $words{$key} } );
        }
    }

    return sort @matchingWords;
}

1;