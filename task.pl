#!/usr/bin/perl -T

my %p;
%p = @ARGV; s/,\z// foreach values %p; # DEPLOYMENT SCRIPT EDITS THIS LINE

use strict;
use Carp::Always;

use Tversky 'cat';

# ------------------------------------------------
# Parameters
# ------------------------------------------------

# Format for delay scenarios: [amount in dollars, delay in years]
my %delay_scenarios =
   (first =>
        [1e4, 1],
    rest =>
       [[1e1, 0],
        [1e1, 1],
        [1e1, 5],
        [1e4, 0],
        [1e4, 5],
        [1e6, 0],
        [1e6, 1],
        [1e6, 5]]);
# Format for risk scenarios: [amount in dollars, probability]
my %risk_scenarios =
   (first =>
        [1e4, .5],
    rest =>
       [[1e1, 1],
        [1e1, .5],
        [1e1, .1],
        [1e4, 1],
        [1e4, .1],
        [1e6, 1],
        [1e6, .5],
        [1e6, .1]]);

sub display_amount
   {my $amount = shift;
        $amount == 1e1 ? '$10 (ten dollars)' :
        $amount == 1e4 ? '$10,000 (ten thousand dollars)' :
        $amount == 1e6 ? '$1,000,000 (a million dollars)' :
                         die 'Unexpected amount';}

sub display_delay
   {my $delay = shift;
        $delay == 0 ? 'immediately'            :
        $delay == 1 ? '1 year from now'        :
                      "$delay years from now";}

sub display_probability
   {my $prob = shift;
    $prob == 1 ? 'for sure' :
        'with probability ' . int($prob * 100) . '%';}

# ------------------------------------------------
# Declarations
# ------------------------------------------------

my $o; # Will be our Tversky object.

sub p ($)
   {"<p>$_[0]</p>"}

# ------------------------------------------------
# Tasks
# ------------------------------------------------

sub linedraw_trial
   {my ($type, $trial, $amount, $trailer) = @_;

    $o->save_once("linedraw_${type}_amount.$trial", sub {$amount});
    $o->save_once("linedraw_${type}_trailer.$trial", sub {$trailer});

    my $amount_str = display_amount $amount;
    my $trailer_str = $type eq 'delay'
      ? display_delay $trailer
      : display_probability $trailer;

    $o->text_entry_page("linedraw_${type}_input.$trial",
         cat(
             p "Imagine that you are awarded a prize of <strong>$amount_str</strong> to be received <strong>$trailer_str</strong>.",
             p 'How would you feel now? Draw a line proportional to how happy you would feel now to be awarded the prize (longer means happier).'),
         multiline => 1,
         max_chars => 5000,
         hint => 'Type a line of hyphens or specify a length.');}

sub linedraw_task
   {my ($type, @instructions) = @_;
    my %scenarios = ($type eq 'delay' ? %delay_scenarios : %risk_scenarios);

    $o->okay_page("linedraw_${type}_instructions", cat map {"<p class='long'>$_</p>"}
        @instructions);

    my $trial = 0;
    linedraw_trial $type, ++$trial, @{$scenarios{first}};
    $o->assign_permutation("linedraw_${type}_permutation",
        ',', 0 .. $#{$scenarios{rest}});
    foreach (split qr/,/, $o->getu("linedraw_${type}_permutation"))
       {linedraw_trial $type, ++$trial, @{$scenarios{rest}[$_]};}}

# ------------------------------------------------
# Mainline code
# ------------------------------------------------

$o = new Tversky
   (cookie_name_suffix => 'Margin',
    here_url => $p{here_url},
    database_path => $p{database_path},
    task => $p{task},

    cookie_lifespan => 2*60*60, # 2 hours

    head => do {local $/; <DATA>},
    footer => "\n\n\n</body></html>\n",

    assume_consent => 1,
    sn_param_without_password => $p{sn_param_without_password},

    experiment_complete => $p{experiment_complete});

$o->run(sub

   {$o->okay_page('preface', $p{preface});

    linedraw_task 'delay',
        q{This is an experiment in imagination (of a pleasant kind). At the top of each of the following pages are an amount of money and a period of time. We ask you to imagine that you just received news that you won a prize of that amount to be received after that time. Then, below the stated amount and time we would like you to draw a horizontal line proportional to how happy you would feel now to be awarded the prize. For the first amount and time, just draw a line you feel comfortable with. After that, if you would feel twice as happy as before then draw a line twice as long. If you would feel half as happy then draw a line half as long, and so forth.},
        q{Draw your line by holding the hyphen key (<code>-</code>) on your keyboard, between the <code>0</code> and <code>=</code> keys. If your input is wider than the text box, it will wrap to the next line. If you wish to express an extremely short or extremely long length, rather than typing hyphens, type a number and unit such as "5 millimeters" or "3 miles".},
        q{Of course there are no right or wrong answers. We just want to know how you would feel if you had gotten the prize. Please take your time and imagine how you feel then draw the line. It's your feelings we're interested in.},
        q{Thank you!};

    linedraw_task 'risk',
        q{Now you'll answer some more questions, which are similar except that the prize is associated with a certain probability of receipt, rather than a delay. Tell us how happy you would feel to be told you had the given probability of receiving the prize. In each case, if you won the prize, you would receive it immediately (with no delay).};

    $o->buttons_page('gender',
        p 'Are you male or female?',
        'Male', 'Female');
    $o->nonneg_int_entry_page('age',
        p 'How old are you?');
    $o->multiple_choice_page('english',
        p 'Which of the following best describes your knowledge of English?',
        Native => 'I am a native speaker of English.',
        Fluent => 'I am <em>not</em> a native speaker of English, but I consider myself fluent.',
        Neither => 'I am not fluent in English.');});

__DATA__

<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Decision-Making</title>

<style type="text/css">

    h1, form, div.expbody p
       {text-align: center;}

    div.expbody p.long, div.debriefing p
       {text-align: left;}

    input.consent_statement
       {border: thin solid black;
        background-color: white;
        color: black;
        margin-bottom: .5em;}

    div.multiple_choice_box
       {display: table;
        margin-left: auto; margin-right: auto;}
    div.multiple_choice_box > div.row
       {display: table-row;}
    div.multiple_choice_box > div.row > div
       {display: table-cell;}
    div.multiple_choice_box > div.row > div.button
       {padding-right: 1em;
        vertical-align: middle;}
    div.multiple_choice_box > div.row > .body
       {text-align: left;
        vertical-align: middle;}

    input.text_entry, textarea.text_entry
       {border: thin solid black;
        background-color: white;
        color: black;}

    textarea.text_entry
       {width: 700px !important;
        font-size: 12px !important;
        font-family: Arial,sans-serif !important;}

</style>
