=head1 NAME

PDL::Graphics::Gnuplot - Gnuplot-based plotting for PDL

=head1 SYNOPSIS

 pdl> use PDL::Graphics::Gnuplot;

 pdl> $x = sequence(101) - 50;
 pdl> gplot($x**2);

 pdl> gplot( {title => 'Parabola with error bars'},
       with => 'xyerrorbars', legend => 'Parabola',
       $x**2 * 10, abs($x)/10, abs($x)*5 );

 pdl> $xy = zeros(21,21)->ndcoords - pdl(10,10);
 pdl> $z = inner($xy, $xy);
 pdl> gplot({title  => 'Heat map', '3d' => 1,
        extracmds => 'set view 0,0'},
        with => 'image', $z*2);

 pdl> $w = gpwin();
 pdl> $pi    = 3.14159;
 pdl> $theta = zeros(200)->xlinvals(0, 6*$pi);
 pdl> $z     = zeros(200)->xlinvals(0, 5);
 pdl> $w->plot3d(cos($theta), sin($theta), $z);


=head1 DESCRIPTION

This module allows PDL data to be plotted using Gnuplot as a backend
for 2D and 3D plotting and image display.  Gnuplot (not affiliated
with the Gnu project) is a venerable, open-source plotting package
that produces both interactive and publication-quality plots on a very
wide variety of output devices.  Gnuplot is a standalone package that
must be obtained separately from this interface module.  It is
available through most Linux repositories, on MacOS via fink and
MacPorts, and from its website L<http://www.gnuplot.info>.

It is not necessary to understand the gnuplot syntax to generate
basic, or even complex, plots - though the full syntax is available
for advanced users who want to take advantage of the full flexibility
of the Gnuplot backend.

The main subroutine that C<PDL::Graphics::Gnuplot> exports by default
is C<gplot()>, which produces one or more overlain plots and/or images
in a single plotting window.  Depending on options, C<gplot()> can 
produce line plots, scatterplots, error boxes, "candlesticks", images,
or any overlain combination of these elements; or perspective views
of 3-D renderings such as surface plots.  

A call to C<gplot()> looks like:

 gplot({temp_plot_options}, # optional hash or array ref
      curve_options, data, data, ... ,
      curve_options, data, data, ... );

PDL::Graphics::Gnuplot also implements an object oriented
interface. Plot objects track individual gnuplot subprocesses.  Direct
calls to C<gplot()> are tracked through a global object that stores
globally set configuration variables.

Gnuplot collects two kinds of options hash: plot options, which
describe the overall structure of the plot being produced (e.g. axis
specifications, window size, and title), from curve options, which
describe the behavior of individual traces or collections of points
being plotted.  In addition, the module itself supports options that
allow direct pass-through of plotting commands to the underlying
gnuplot process.

=head2 Basic plotting

Gnuplot generates many kinds of plot, from basic line plots and histograms
to scaled labels.  Individual plots can be 2-D or 3-D, and different sets 
of plot styles are supported in each mode.  Plots can be sent to a variety
of devices; see the description of plot options, below.

You select a plot style with the "with" curve option, as in

 $x = xvals(51)-25; $y = $x**2;
 gplot(with=>'points', $x, $y);  # Draw points on a parabola
 gplot(with=>'lines', $x, $y);   # Draw a parabola
 gplot({title=>"Parabolic fit"},
       with=>"yerrorbars", legend=>"data", $x, $y+(random($y)-0.5)*2*$y/20, pdl($y/20),
       with=>"lines",      legend=>"fit",  $x, $y);

See below for supported plot styles.

=head2 Options arguments

The plot options are parameters that affect the whole plot, like the title of
the plot, the axis labels, the extents, 2d/3d selection, etc. All the plot
options are described below in L</"Plot options">.

The curve options are parameters that affect only one curve in particular. Each
call to C<plot()> can contain many curves, and options for a particular curve
I<precede> the data for that curve in the argument list. Furthermore, I<curve
options are all cumulative>. So if you set a particular style for a curve, this
style will persist for all the following curves, until this style is turned
off. The only exception to this is the C<legend> option, since it's very rarely
a good idea to have multiple curves with the same label. An example:

 gplot( with => 'points', $x, $a,
        y2   => 1,        $x, $b,
        with => 'lines',  $x, $c );

This plots 3 curves: $a vs. $x plotted with points on the main y-axis (this is
the default), $b vs. $x plotted with points on the secondary y axis, and $c
vs. $x plotted with lines also on the secondary y axis. All the curve options
are described below in L</"Curve options">.

=head2 Data arguments

Following the curve options in the C<plot()> argument list is the actual data
being plotted. Each output data point is a "tuple" whose size varies depending on
what is being plotted. For example if we're making a simple 2D x-y plot, each
tuple has 2 values; if we're making a 3d plot with each point having variable
size and color, each tuple has 5 values (x,y,z,size,color). Each tuple element 
must be passed separately.  For ordinary (non-curve) plots, the 0 dim of the 
tuple elements runs across plotted point.  PDL threading is active, so multiple 
curves with similar curve options can be plotted by stacking data inside the 
passed-in piddles.  

An example:

 my $pi    = 3.14159;
 my $theta = xvals(201) * 6 * $pi / 200;
 my $z     = xvals(201) * 5 / 200;

 plot( {'3d' => 1, title => 'double helix'},
       { with => 'linespoints pointsize variable pointtype 2 palette',
         legend => ['spiral 1','spiral 2'] },
         pdl( cos($theta), -cos($theta) ),       # x
         pdl( sin($theta), -sin($theta) ),       # y
         $z,                                     # z
         (0.5 + abs(cos($theta))),               # pointsize
         sin($theta/3)                           # color
    );

This is a 3d plot with variable size and color. There are 5 values in the tuple,
which we specify. The first 2 piddles have dimensions (N,2); all the other
piddles have a single dimension. Thus the PDL threading generates 2 distinct
curves, with varying values for x,y and identical values for everything else. To
label the curves differently, 2 different sets of curve options are given. Since
the curve options are cumulative, the style and tuplesize needs only to be
passed in for the first curve; the second curve inherits those options.

=head3 Implicit domains

When making a simple 2D plot, if exactly 1 dimension is missing,
PDL::Graphics::Gnuplot will use C<sequence(N)> as the domain. This is why code
like C<plot(pdl(1,5,3,4,4) )> works. Only one piddle is given here, but a
default tuplesize of 2 is active, and we are thus exactly 1 piddle short. This
is thus equivalent to C<plot( sequence(5), pdl(1,5,3,4,4) )>.

If plotting in 3d or displaying an image, an implicit domain will be
used if we are exactly 2 piddles short. In this case,
PDL::Graphics::Gnuplot will use a 2D grid as a domain. Example:

 my $xy = zeros(21,21)->ndcoords - pdl(10,10);
 plot({'3d' => 1},
       with => 'points', inner($xy, $xy));
 plot( with => 'image',  sin(rvals(51,51)) );

Here the only given piddle has dimensions (21,21). This is a 3D plot, so we are
exactly 2 piddles short. Thus, PDL::Graphics::Gnuplot generates an implicit
domain, corresponding to a 21-by-21 grid.

One thing to watch out for it to make sure PDL::Graphics::Gnuplot doesn't get
confused about when to use implicit domains. For example, C<plot($a,$b)> is
interpreted as plotting $b vs $a, I<not> $a vs an implicit domain and $b vs an
implicit domain. If 2 implicit plots are desired, add a separator:
C<plot($a,{},$b)>. Here C<{}> is an empty curve options hash. If C<$a> and C<$b>
have the same dimensions, one can also do C<plot($a->cat($b))>, taking advantage
of PDL threading.

=head2 Images

PDL::Graphics::Gnuplot supports image plotting in three styles via the "with"
curve option. 

The "image" style accepts a single image plane and displays it using
the palette (pseudocolor map) that is specified in the plot options for that plot.
As a special case, if you supply as data a (WxHx3) PDL it is treated as an RGB
image and displayed with the "rgbimage" style (below).  For quick
image display there is also an "image" method:

 use PDL::Graphics::Gnuplot qw/image/;
 $im = sin(rvals(51,51)/2);
 image( $im );                # display the image
 gplot( with=>'image', $im );  # display the image (longer form)

The colors are autoscaled in both cases.  To set a particular color range, use
the 'cbrange' plot option:

 image( {cbrange=>[0,1]}, $im );

You can plot rgb images directly with the image style, just by including a 
3rd dimension of size 3 on your image:

 $rgbim = pdl( xvals($im), yvals($im),rvals($im)/sqrt(2));
 image( $rgbim );                # display an RGB image
 image( with=>'image', $rgbim ); # display an RGB image (longer form)

Some additional plot styles exist to specify RGB and RGB transparent forms
directly.  These are the "with" styles "rgbimage" and "rgbalpha".  For each
of them you must specify the channels as separate PDLs:

 plot( with=>'rgbimage', $rgbim->dog );           # RGB  the long way
 plot( with=>'rgbalpha', $rgbim->dog, ($im>0) );  # RGBA the long way 

According to the gnuplot specification you can also give X and Y
values for each pixel, as in

 plot( with=>'image', xvals($im), yvals($im), $im )

but this appears not to work properly for anything more complicated
than a trivial matrix of X and Y values.

=head2 Interactivity

The graphical backends of Gnuplot are interactive, allowing the user
to pan, zoom, rotate and measure the data in the plot window. See the
Gnuplot documentation for details about how to do this. Some terminals
(such as wxt) are persistently interactive, and the rest of this
section does not apply to them. Other terminals (such as x11) maintain
their interactivity only while the underlying gnuplot process is
active -- i.e. until another plot is created with the same PDL::Graphics::Gnuplot
object, or until the perl process exits (whichever comes first).

=head1 PLOT OPTIONS

Gnuplot controls plot style with "plot options" that configure and
specify virtually all aspects of the plot to be produced.   Plot
options are tracked as stored state in the PDL::Graphics::Gnuplot
object.  You can set them by passing them in to the constructor, to an
C<options> method, or to the C<plot> method itself.

Nearly all the underlying Gnuplot plot options are supported, as well
as some additional options that are parsed by the module itself for
convenience.

=head2 Output: terminal, termoption, output, device, hardcopy

C<terminal> sets the output device type for Gnuplot, and C<output> sets the 
actual output file or window number.  

C<device> and C<hardcopy> are for convenience.  C<device> offers a 
PGPLOT-style device specifier in "filename/device" format (the "filename"
gets sent to the "output" option, the "device" gets sent to the "terminal"
option). C<hardcopy> takes an output file name and attempts to parse out a 
file suffix and infer a device type.

For finer grained control of the plotting environment, you can send 
"terminal options" to Gnuplot.  If you set the terminal directly with 
plot options, you can include terminal options by interpolating them 
into a string, as in C<terminal jpeg interlace butt crop>, or you can
use the constructor C<new> (also exported as C<gpwin>), which parses
terminal options as an argument list.  

The routine C<PDL::Graphics::Gnuplot::terminfo> prints a list of all
availale terminals or, if you pass in a terminal name, options accepted
by that terminal.


=head2 Titles: title, (x|x2|y|y2|z|cb)label, key

Gnuplot supports "enhanced" text escapes on most terminals; see "text",
below.

The C<title> option lets you set a title for the whole plot.

Individual plot components are labeled with the C<label> options.
C<xlabel>, C<x2label>, C<ylabel>, and C<y2label> specify axis titles
for 2-D plots.  The C<zlabel> works for 3-D plots.  The C<cblabel> option
sets the label for the color box, in plot types that have one (e.g.
image display).

(Don't be confused by C<clabel>, which doesnt' set a label at all, rather 
specifies the printf format used by contour labels in contour plots.)

C<key> controls where the plot key (that relates line/symbol style to label)
is placed on the plot.  It takes a scalar boolean indicating whether to turn the
key on (with default values) or off, or a list ref containing any of the following
arguments (all are optional) in the order listed:

=over 3

=item ( on | off ) - turn the key on or off

=item ( inside | outside | lmargin | rmargin | tmargin | bmargin | at <pos> )

These keywords set the location of the key -- "inside/outside" is
relative to the plot border; the margin keywords indicate location in
the margins of the plot; and at <pos> (where <pos> is a 2-list
containing (x,y): C<key=>[at=>[0.5,0.5]]>) is an exact location to place the key.

=item ( left | right | center ) ( top | bottom | center ) - horiz./vert. alignment

=item ( vertical | horizontal ) - stacking direction within the key

=item ( Left | Right ) - justification of plot labels within the key (note case)

=item [no]reverse - switch order of label and sample line

=item [no]invert - invert the stack order of the labels

=item samplen <length> - set the length of the sample lines

=item spacing <dist> - set the spacing between adjacent labels in the list

=item [no]autotitle - control whether labels are generated when not specified

=item title "<text>" - set a title for the key

=item [no]enhanced - override terminal settings for enhanced text interpretation

=item font "<face>,<size>" - set font for the labels

=item textcolor <colorspec> 

=item [no]box linestyle <ls> linetype <lt> linewidth <lw> - control box around the key

=back

=head2 axis, grid, and border control: grid, (x|x2|y|y2|z)zeroaxis, border

Normally, tick marks and labels are applied to the border of a plot,
and no extra axes (e.g. the y=0 line) nor coordinate grids are shown.  You can
specify which (if any) zero axes should be drawn, and which (if any)
borders should be drawn.

The C<border> option controls whether the plot itself has a border
drawn around it.  You can feed it a scalar boolean value to indicate
whether borders should be drawn around the plot -- or you can feed in a list
ref containing options.  The options are all optional but must be supplied
in the order given.

=over 3

=item <integer> - packed bit flags for which border lines to draw

The default if you set a true value for C<border> is to draw all border lines. 
You can feed in a single integer value containing a bit mask, to draw only some
border lines.  From LSB to MSB, the coded lines are bottom, left, top, right for 
2D plots -- e.g. 5 will draw bottom and top borders but neither left nor right.

In three dimensions, 12 bits are used to describe the twelve edges of
a cube surrounding the plot.  In groups of three, the first four
control the bottom (xy) plane edges in the same order as in the 2-D
plots; the middle four control the vertical edges that rise from the
clockwise end of the bottom plane edges; and the last four control the
top plane edges.

=item ( back | front ) - draw borders first or last (controls hidden line appearance)

=item linewidth <lw>, linestyle <ls>, linetype <lt> 

These are Gnuplot's usual three options for line control.

=back

To draw each axis set the appropriate "zeroaxis" parameter -- i.e. to draw
the X axis (y=0), use C<xzeroaxis=>1>.  If you just want the axis
turned on with default values, you can feed in a Boolean scalar; if
you want to set its parameters, you can feed in a list ref containing
linewidth, linestyle, and linetype (with appropriate parameters for each), e.g.
C<xzeroaxis=>[linewidth=>2]>.

To draw a coordinate grid with default values, set C<grid=>1>.  For more 
control, feed in a list ref with zero or more of the following parameters, in order:

=over 3

=item tics specifications

These keywords indicate whether gridlines should be drawn on axis tics (see below) for each axis.  Each one takes the form of either "no" or "m" or "", followed by an axis name and "tics" -- e.g. C<grid=>["noxtics","ymtics"]> draws no X gridlines and draws (horizontal) Y gridlines on Y axis major and minor tics, while C<grid=>["xtics","ytics"]> or C<grid=>["xtics ytics"]> will draw both vertical (X) and horizontal (Y) grid lines on major tics.

=head2 Axis ranging and mode: (x|x2|y|y2|z|r|cb|t|u|v)range, autoscale, logscale

Gnuplot accepts explicit ranges as plot options for all axes.  Each option
accepts a list ref with (min, max).  If either min or max is missing, then
the opposite limit is autoscaled.  The x and y ranges refer to the usual 
ordinate and abscissa of the plot; x2 and y2 refer to alternate ordinate and 
abscissa; z if for 3-D plots; r is for polar plots; t, u, and v are for parametric
plots.  cb is for the color box on plots that include it (see "color", below).

C<rrange> is used for radial coordinates (which
are accessible using the C<mapping> plot option, below).

C<cbrange> (for 'color box range') sets the range of values over which
palette colors (either gray or pseudocolor) are matched.  It is valid
in any color-mapped plot (including images or palette-mapped lines or
points), even if no color box is being displayed for this plot.

C<trange>, C<urange>, and C<vrange> set ranges for the parametric coordinates
if you are plotting a parametric curve.

By default all axes are autoscaled unless you specify a range on that
axis, and partially (min or max) autoscaled if you specify a partial
range on that axis.  C<autoscale> allows more explicit control of how
autoscaling is performed, on an axis-by-axis basis.  It accepts a list
ref, each element of which specifies how a single axis should be
autoscaled.  Each element contains an axis name followed by one of
"fix,"min","max","fixmin", or "fixmax", e.g. 

 autoscale=>['xmax','yfix']

To not autoscale an axis at all, specify a range for it. The fix style of 
autoscaling forces the autoscaler to use the actual min/max of the data as
the limit for the corresponding axis -- by default the axis gets extended
to the next minor tic (as set by the autoticker or by a tic specification, see
below).

C<logscale> allows you to turn on logarithmic scaling for any or all
axes, and to set the base of the logarithm.  It takes a list ref, the
first element of which is a string mushing together the names of all
the axes to scale logarithmically, and the second of which is the base
of the logarithm: C<logscale=>[xy=>10]>.  You can also leave off the
base if you want base-10 logs: C<logscale=>['xy']>.

=head2 Axis tick marks - [m](x|x2|y|y2|z|cb)tics

Label tick marks are called "tics" within Gnuplot, and they are extensively
controllable via the "<axis>tics" options.  In particular, major and minor
ticks are supported, as are arbitrarily variable length ticks, non-equally
spaced ticks, and arbitrarily labelled ticks.  Support exists for time formatted
ticks (see "Time data" below).

By default, gnuplot will automatically place major and minor ticks.
You can turn off ticks on an axis by setting the appropriate <foo>tics
option to a defined, false scalar value (e.g. C<xtics=>0>), and turn them
on with default values by setting the option to a true scalar value
(e.g. C<xtics=>1>). 

If you prepend an 'm' to any tics option, it affects minor tics instead of
major tics (major tics typically show units; minor tics typically show fractions
of a unit).

Each tics option can accept a list ref containing options to pass
directly to Gnuplot (they are not parsed further -- though a future
version of PDL::Graphics::Gnuplot may accept a hash ref and parse it
into an options string).  You can interpolate all the words into a
single string, provided it is contained in a list ref.  The keywords
are all optional, but must appear in the order given here, and may not
be abbreviated.  They are:

=over 2

=item * ( axis | border ) - are tics on the axis, or on the plot border?

=item * ( nomirror | mirror ) - place mirrored tics on the opposite axis/border?

=item * ( in | out ) - controls tic direction relative to the plot

=item * scale ( default | <major>[,<minor>] ) - multiplier on tic length

=item * ( norotate | rotate [by <ang>] ) - turn label text by 90deg or specified angle

=item * ( nooffset | offset <x>,<y>[,<z>] ) - offset label text from default position

=item * (autofreq | <incr> | <start>,<incr>[,<end>] | <label-list>) - set tic locations

=item * format "<formatstring>" - printf-style formatting for tic labels

=item * font "<font>[,<size>]" - set font name and size (system font name)

=item * rangelimited - limit tics to the range of values actually present in the plot

=item * textcolor <colorspec> - set the color of the ticks (see "color specs" below)

=back

For example, to turn on inward mirrored X axis ticks with diagonal Arial 9 text, use:

 xtics => ['axis','mirror','in','rotate by 45','font "Arial,9"']

=head2 Time/date values - (x|x2|y|y2|z|cb)(m|d)tics, (x|x2|y|y2|z|cb)data

Gnuplot contains support for plotting time, date, or elapsed time on
any of its axes.  There are three main methods, which are mutually exclusive
(i.e. you should not attempt to use two at once on the same axis).

=over 3

=item B<Plotting timestamps using UNIX times>

You can set any axis to plot timestamps rather than numeric values by
setting the corresponding "data" plot option to "time",
e.g. C<xdata=>"time">.  If you do so, then numeric values in the
corresponding data are interpreted as UNIX times (seconds since the
UNIX epoch).  No provision is made for UTC->TAI conversion (yet).  You
can format how the times are plotted with the "format" option in the
various "tics" options(above).  Output specifiers should be in
UNIX strftime(3) format -- for example, 
 
 xdata=>"time",xtics=>['format "%G-%m-%dT%H:%M:%S"']

will plot UNIX times as ISO timestamps in the ordinate.

=item B<day-of-week plotting>

If you just want to plot named days of the week, you can instead use 
the dtics options set plotting to day of week, where 0 is Sunday and 6
is Saturday; values are interpreted modulo 7.  For example,
C<xmtics=>1,xrange=>[-4,9]> will plot two weeks from Wednesday to
Wednesday.

=item B<month-of-year plotting>

The mtics options set plotting to months of the year, where 1 is January and 12 is 
December, so C<xdtics=>1, xrange=>[0,4]> will include Christmas through Easter.

=back

=head2 Plot location and size - (t|b|l|r)margin, offsets, origin, size, justify, clip

Adjusting the size, location, and margins of the plot on the plotting
surface is something of a null operation for most single plots -- but
you can tweak the placement and size of the plot with these options.
That is particularly useful for multiplots, where you might like to
make an inset plot or to lay out a set of plots in a custom way.

The margin options accept scalar values -- either a positive number of
character heights or widths of margin around the plot compared to the
edge of the device window, or a string that starts with "at screen "
and interpolates a number containing the fraction of the plot window
offset.  The "at screen" technique allows exact plot placement and is
an alternative to the C<origin> and C<size> options below.

The C<offsets> option allows you to put an empty boundary around the
data, inside the plot borders, in an autosacaled graph.  The offsets
only affect the x1 and y1 axes, and only in 2D plot commands.
C<offsets> accepts a list ref with four values for the offsets, which
are given in scientific (plotted) axis units.

The C<origin> option lets you specify the origin (lower left corner)
of an individual plot on the plotting window.  The coordinates are 
screen coordinates -- i.e. fraction of the total plotting window.  

The size option lets you adjust the size and aspect ratio of the plot, 
as an absolute fraction of the plot window size.  You feed in fractional
ratios, as in C<size=>[$xfrac, $yfrac]>.  You can also feed in some keywords
to adjust the aspect ratio of the plot.  The size option overrides any 
autoscaling that is done by the auto-layout in multiplot mode, so use 
with caution -- particularly if you are multiplotting.  You can use
"size" to adjust the aspect ratio of a plot, but this is deprecated 
in favor of the pseudo-option C<justify>.

C<justify> sets the scientific aspect ratio of a 2-D plot.  Unity 
yields a plot with a square scientific aspect ratio.  Larger
numbers yield taller plots. 

C<clip> controls the border between the plotted data and the border of the plot.
There are three clip types supported:   points, one, and two.  You can set them 
independently by passing in booleans with their names: C<clip=>[points=>1,two=>0]>.

=head2 Color: colorbox, palette, clut

Color plots are supported via RGB and pseudocolor.  Plots that use pseudcolor or
grayscale can have a "color box" that shows the photometric meaning of the color.

The colorbox generally appears when necessary but can be controlled manually
with the C<colorbox> option.  C<colorbox> accepts a scalar boolean value indicating
whether or no to draw a color box, or a list ref containing additional options.  
The options are all, well, optional but must appear in the order given:

=over 3

=item ( vertical | horizontal ) - indicates direction of the gradient in the box

=item ( default | user ) - indicates user origin and size

If you specify C<default> the colorbox will be placed on the right-hand side of the plot; if you specify C<user>, you give the location and size in subsequent arguments:

 colorbox => [ 'user', 'origin'=>"$x,$y", 'size' => "$x,$y" ]

=item ( front | back ) - draws the colorbox before or after the plot

=item ( noborder | bdefault | border <line style> ) - specify border

The line style is a numeric type as described in the gnuplot manual.

=back

The C<palette> option offers many arguments that are not fully
documented in this version but are explained in the gnuplot manual.
It offers complete control over the pseudocolor mapping function.

For simple color maps, C<clut> gives access to a set of named color
maps.  (from "Color Look Up Table").  A few existing color maps are:
"default", "gray", "sepia", "ocean", "rainbow", "heat1", "heat2", and
"wheel".  To see a complete list, specify an invalid table,
e.g. "clut=>'xxx'".  (This should be improved in a future version).

=head2 3-D: trid, view, pm3d, hidden3d, dgrid3d, surface, xyplane, mapping

If C<trid> or its synonym C<3d> is true, Gnuplot renders a 3-D plot.
This changes the default tuple size from 2 to 3.  This
option is used to switch between the Gnuplot "plot" and "splot"
command, but it is tracked with persistent state just as any other
option.

The C<view> option controls the viewpoint of the 3-D plot.  It takes a
list of numbers: C<view=>[$rot_x, $rot_z, $scale, $scale_z]>.  After
each number, you can omit the subsequent ones.  Alternatively,
C<view=>['map']> represents the drawing as a map (e.g. for contour
plots) and C<view=>[equal=>'xy']> forces equal length scales on the X
and Y axes regardless of perspective, while C<view=>[equal=>'xyz']>
sets equal length scales on all three axes.

The C<pm3d> option accepts several parameters to control the pm3d plot style,
which is a palette-mapped 3d surface.  They are not documented here in this
version of the module but are explained in the gnuplot manual.  

C<hidden3d> accepts a list of parameters to control how hidden surfaces are
plotted (or not) in 3D. It accepts a boolean argument indicating whether to hide
"hidden" surfaces and lines; or a list ref containing parameters that control how 
hidden surfaces and lines are handled.  For details see the gnuplot manual.

C<xyplane> sets the location of that plane (which is drawn) relative
to the rest of the plot in 3-space.  It takes a single string: "at" or
"relative", and a number.  C<xyplane=>[at=>$z]> places the XY plane at the
stated Z value (in scientific units) on the plot.  C<xyplane=>[relative=>$frac]>
places the XY plane $frac times the length of the scaled Z axis *below* the Z 
axis (i.e. 0 places it at the bottom of the plotted Z axis; and -1 places it 
at the top of the plotted Z axis).

C<mapping> takes a single string: "cartesian", "spherical", or
"cylindrical".  It determines the interpretation of data coordinates
in 3-space. (Compare to the C<polar> option in 2-D).

=head2 Contour plots - contour, cntrparam

Contour plots are only implemented in 3D.  To make a normal 2D contour
plot, use 3-D mode, but set the view to "map" - which projects the 3-D
plot onto its 2-D XY plane. (This is convoluted, for sure -- future
versions of this module may have a cleaner way to do it).

C<contour> enables contour drawing on surfaces in 3D.  It takes a
single string, which should be "base", "surface", or "both".

C<cntrparam> manages how contours are generated and smoothed.  It
accepts a list ref with a collection of Gnuplot parameters that are
issued one per line; refer to the Gnuplot manual for how to operate
it.

=head2 Polar plots - polar, angles, mapping

You can make 2-D polar plots by setting C<polar> to a true value.  The 
ordinate is then plotted as angle, and the abscissa is radius on the plot.
The ordinate can be in either radians or degrees, depending on the 
C<angles> parameter

C<angles> takes either "degrees" or "radians" (default is radians).

C<mapping> is used to set 3-D polar plots, either cylindrical or spherical 
(see the section on 3-D plotting, above).

=head2 Markup - label, arrow, object

You specify plot markup in advance of the plot command, with plot
options.  The options give you access to a collection of (separately)
numbered descriptions that are accumulated into the plot object.  To
add a markup object to the next plot, supply the appropriate options
as a list ref or as a single string.  To specify all markup objects
at once, supply the appropriate options for all of them as a nested 
list-of-lists.

To modify an object, you can specify it by number, either by appending
the number to the plot option name (e.g. C<arrow3>) or by supplying it
as the first element of the option list for that object.  

To remove all objects of a given type, supply undef (e.g. C<arrow=>undef>).

For example, to place two labels, use the plot option:

 label => [["Upper left",at=>"10,10"],["lower right",at=>"20,5"]];

To add a label to an existing plot object, if you don't care about what
index number it gets, do this:

 $w->options( label=>["my new label",at=>"10,20"] );

If you do care what index number it gets (or want to replace an existing label), 
do this:

 $w->options( label=>[$n, "my replacement label", at=>"10,20"] );

where C<$w> is a Gnuplot object and C<$n> contains the label number
you care about.


=head3 label - add a text label to the plot.

The C<label> option allows adding small bits of text at arbitrary
locations on the plot.

Each label specifier list ref accepts the following suboptions, in 
order.  All of them are optional -- if no options other than the index
tag are given, then any existing label with that index is deleted.

For examples, please refer to the Gnuplot 4.4 manual, p. 117.

=over 3

=item <tag> - optional index number (integer)

=item <label text> - text to place on the plot.

You may supply double-quotes inside the string, but it is not
necessary in most cases (only if the string contains just an integer
and you are not specifying a <tag>.

=item at <position> - where to place the text (sci. coordinates)

The <position> should be a string containing a gnuplot position specifier.
At its simplest, the position is just two numbers separated by
a comma, as in C<label2=>["foo",at=>"5,3">, to specify (X,Y) location 
on the plot in scientific coordinates.  Each number can be preceded
by a coordinate system specifier; see the Gnuplot 4.4 manual (page 20) 
for details.

=item ( left | center | right ) - text placement rel. to position

=item rotate [ by <degrees> ] - text rotation

If "rotate" appears in the list alone, then the label is rotated 90 degrees
CCW (bottom-to-top instead of left-to-right).  The following "by" clause is
optional.

=item font "<name>,<size>" - font specifier

The <name>,<size> must be double quoted in the string (this may be fixed
in a future version), as in

 C<label3=>["foo",at=>"3,4",font=>'"Helvetica,18"']>.

=item noenhanced - turn off gnuplot enhanced text processing (if enabled)

=item ( front | back ) - rendering order (last or first)

=item textcolor <colorspec> 

=item (point <pointstyle> | nopoint ) - control whether the exact position is marked

=item offset <offset> - offfset from position (in points).

=back

=head3 arrow - place an arrow or callout line on the plot

Works similarly to the C<label> option, but with an arrow instead of text.

The arguments, all of which are optional but which must be given in the order listed,
are:

=over 3

=item from <position> - start of arrow line

The <position> should be a string containing a gnuplot position specifier.
At its simplest, the position is just two numbers separated by
a comma, as in C<label2=>["foo",at=>"5,3">, to specify (X,Y) location 
on the plot in scientific coordinates.  Each number can be preceded
by a coordinate system specifier; see the Gnuplot 4.4 manual (page 20) 
for details.

=item ( to | rto ) <position>  - end of arrow line

These work like C<from>.  For absolute placement, use "to".  For placement
relative to the C<from> position, use "rto". 

=item (arrowstyle | as) <arrow_style>

This specifies that the arrow be drawn in a particualr predeclared numerical
style.  If you give this parameter, you shoudl omit all the following ones.

=item ( nohead | head | backhead | heads ) - specify arrowhead placement

=item size <length>,<angle>,<backangle> - specify arrowhead geometry

=item ( filled | empty | nofilled ) - specify arrowhead fill

=item ( front | back ) - specify drawing order ( last | first )

=item linestyle <line_style> - specify a numeric linestyle

=item linetype <line_type> - specify numeric line type

=item linewidth <line_width> - multiplier on the width of the line

=back

=head3 object - place a shape on the graph

C<object>s are rectangles, ellipses, circles, or polygons that can be placed
arbitrarily on the plotting plane.

The arguments, all of which are optional but which must be given in the order listed, are:

=over 3

=item <object-type> <object-properties> - type name of the shape and its type-specific properties

The <object-type> is one of four words: "rectangle", "ellipse", "circle", or "polygon".  

You can specify a rectangle with C<from=>$pos1, [r]to=>$pos2>, with C<center=>$pos1, size=>"$w,$h">,
or with C<at=>$pos1,size=>"$w,$h">.

You can specify an ellipse with C<at=>$pos, size=>"$w,$h"> or C<center=>$pos size=>"$w,$h">, followed
by C<angle=>$a>.

You can specify a circle with C<at=>$pos, size=>"$w,$h"> or C<center=>$pos size=>"$w,$h">, followed 
by C<size=>$radius> and (optionally) C<arc=>"[$begin:$end]">.

You can specify a polygon with C<from=>$pos1,to=>$pos2,to=>$pos3,...to=>$posn> or with 
C<from=>$pos1,rto=>$diff1,rto=>$diff2,...rto=>$diffn>.

=item ( front | back | behind ) - draw the object last | first | really-first.

=item fc <colorspec> - specify fill color

=item fs <fillstyle> - specify fill style

=item lw <width> - multiplier on line width

=back

=head2 Appearance tweaks - bars, boxwidth, isosamples, pointsize, style

TBD - more to come.

=head2 Locale/internationalization - locale, decimalsign

C<locale> is used to control date stamp creation.  See the gnuplot manual.

C<decimalsign>  accepts a character to use in lieu of a "." for the decimalsign.
(e.g. in European countries use C<decimalsign=>','>).

=head2 Miscellany: globalwith, timestamp, zero, fontpath, binary

If no valid 'with' curve option is given, use this as a default

=head2 Advanced Gnuplot tweaks: topcmds, extracmds, bottomcmds, binary, dump, log

Plotting is carried out by sending a collection of commands to an underlying
gnuplot process.  In general, the plot options cause "set" commands to be 
sent, configuring gnuplot to make the plot; these are followed by a "plot" or 
"splot" command and by any cleanup that is necessary to keep gnuplot in a known state.

Provisions exist for sending commands directly to Gnuplot as part of a plot.  You
can send commands at the top of the configuration but just under the initial
"set terminal" and "set output" commands (with the C<topcmds> option), at the bottom
of the configuration and just before the "plot" command (with the C<extracmds> option),
or after the plot command (with the C<bottomcmds> option).  Each of these plot
options takes a list ref, each element of which should be one command line for
gnuplot.

Most plotting is done with binary data transfer to Gnuplot; however, due to 
some bugs in Gnuplot binary handling, certain types of plot data are sent in ASCII.
In particular, time series data require transmission in ASCII (as of Gnuplot 4.4). 
You can force ASCII transmission of all but image data by explicitly setting the
C<binary=>0> option.

C<dump> is used for debugging. If true, it writes out the gnuplot commands to STDOUT
I<instead> of writing to a gnuplot process. Useful to see what commands would be
sent to gnuplot. This is a dry run. Note that this dump will contain binary
data, if the 'binary' option is given (see below)

=item log

Used for debugging. If true, writes out the gnuplot commands to STDERR I<in
addition> to writing to a gnuplot process. This is I<not> a dry run: data is
sent to gnuplot I<and> to the log. Useful for debugging I/O issues. Note that
this log will contain binary data, if the 'binary' option is given (see below)

=back

=head1 CURVE OPTIONS 

The curve options describe details of specific curves within a plot. 
They are in a hash, whose keys are as follows:

=over 2

=item legend

Specifies the legend label for this curve

=item with

Specifies the style for this curve. The value is passed to gnuplot
using its 'with' keyword, so valid values are whatever gnuplot
supports.  See below for a list of supported curve styles.

=item y2

If true, requests that this curve be plotted on the y2 axis instead of the main y axis

=item tuplesize

Specifies how many values represent each data point. For 2D plots this defaults
to 2; for 3D plots this defaults to 3.

=back

=head1 RECIPES

Most of these come directly from Gnuplot commands. See the Gnuplot docs for
details.

=head2 2D plotting

If we're plotting a piddle $y of y-values to be plotted sequentially (implicit
domain), all you need is

  plot($y);

If we also have a corresponding $x domain, we can plot $y vs. $x with

  plot($x, $y);

=head3 Simple style control

To change line thickness:

  plot(with => 'lines linewidth 4', $x, $y);

To change point size and point type:

  plot(with => 'points pointtype 4 pointsize 8', $x, $y);

=head3 Errorbars

To plot errorbars that show $y +- 1, plotted with an implicit domain

  plot(with => 'yerrorbars', tuplesize => 3,
       $y, $y->ones);

Same with an explicit $x domain:

  plot(with => 'yerrorbars', tuplesize => 3,
       $x, $y, $y->ones);

Symmetric errorbars on both x and y. $x +- 1, $y +- 2:

  plot(with => 'xyerrorbars', tuplesize => 4,
       $x, $y, $x->ones, 2*$y->ones);

To plot asymmetric errorbars that show the range $y-1 to $y+2 (note that here
you must specify the actual errorbar-end positions, NOT just their deviations
from the center; this is how Gnuplot does it)

  plot(with => 'yerrorbars', tuplesize => 4,
       $y, $y - $y->ones, $y + 2*$y->ones);

=head3 More multi-value styles

In Gnuplot 4.4.0, these generally only work in ASCII mode. This is a bug in
Gnuplot that will hopefully get resolved.

Plotting with variable-size circles (size given in plot units, requires Gnuplot >= 4.4)

  plot(with => 'circles', tuplesize => 3,
       $x, $y, $radii);

Plotting with an variably-sized arbitrary point type (size given in multiples of
the "default" point size)

  plot(with => 'points pointtype 7 pointsize variable', tuplesize => 3,
       $x, $y, $sizes);

Color-coded points

  plot(with => 'points palette', tuplesize => 3,
       $x, $y, $colors);

Variable-size AND color-coded circles. A Gnuplot (4.4.0) bug make it necessary to
specify the color range here

  plot(cbmin => $mincolor, cbmax => $maxcolor,
       with => 'circles palette', tuplesize => 4,
       $x, $y, $radii, $colors);

=head2 3D plotting

General style control works identically for 3D plots as in 2D plots.

To plot a set of 3d points, with a square aspect ratio (squareness requires
Gnuplot >= 4.4):

  plot3d(square => 1, $x, $y, $z);

If $xy is a 2D piddle, we can plot it as a height map on an implicit domain

  plot3d($xy);

Complicated 3D plot with fancy styling:

  my $pi    = 3.14159;
  my $theta = zeros(200)->xlinvals(0, 6*$pi);
  my $z     = zeros(200)->xlinvals(0, 5);

  plot3d(title => 'double helix',

         { with => 'pointslines pointsize variable pointtype 7 palette', tuplesize => 5,
           legend => 'spiral 1' },
         { legend => 'spiral 2' },

         # 2 sets of x, 2 sets of y, single z
         PDL::cat( cos($theta), -cos($theta)),
         PDL::cat( sin($theta), -sin($theta)),
         $z,

         # pointsize, color
         0.5 + abs(cos($theta)), sin(2*$theta) );

3D plots can be plotted as a heat map. As of Gnuplot 4.4.0, this doesn't work in binary.

  plot3d( extracmds => 'set view 0,0',
          with => 'image',
          $xy );

=head2 Hardcopies

To send any plot to a file, instead of to the screen, one can simply do

  plot(hardcopy => 'output.pdf',
       $x, $y);

The C<hardcopy> option is a shorthand for the C<terminal> and C<output>
options. If more control is desired, the latter can be used. For example to
generate a PDF of a particular size with a particular font size for the text,
one can do

  plot(terminal => 'pdfcairo solid color font ",10" size 11in,8.5in',
       output   => 'output.pdf',
       $x, $y);

This command is equivalent to the C<hardcopy> shorthand used previously, but the
fonts and sizes can be changed.


=head1 Methods 

=cut

package PDL::Graphics::Gnuplot;

use strict;
use warnings;
use PDL;
use List::Util qw(first);
use Storable qw(dclone);
use IPC::Open3;
use IPC::Run;
use IO::Select;
use Symbol qw(gensym);
use Time::HiRes qw(gettimeofday tv_interval);

use base 'Exporter';
our @EXPORT_OK = qw(plot plot3d plotlines plotpoints);

# when testing plots with ASCII i/o, this is the unit of test data
my $testdataunit_ascii = "10 ";

# if I call plot() as a global function I create a new PDL::Graphics::Gnuplot
# object. I would like the gnuplot process to persist to keep the plot
# interactive at least while the perl program is running. This global variable
# keeps the new object referenced so that it does not get deleted. Once can
# create their own PDL::Graphics::Gnuplot objects, but there's one free global
# one available
my $globalPlot;

# I make a list of all the options. I can use this list to determine if an
# options hash I encounter is for the plot, or for a curve
my @allPlotOptions = qw(3d dump binary log
                        extracmds nogrid square square_xy title
                        hardcopy terminal output
                        globalwith
                        xlabel xmax xmin
                        y2label y2max y2min
                        ylabel ymax ymin
                        zlabel zmax zmin
                        cbmin cbmax);
my %plotOptionsSet;
foreach(@allPlotOptions) { $plotOptionsSet{$_} = 1; }

my @allCurveOptions = qw(legend y2 with tuplesize);
my %curveOptionsSet;
foreach(@allCurveOptions) { $curveOptionsSet{$_} = 1; }


# get a list of all the -- options that this gnuplot supports
my %gnuplotFeatures = _getGnuplotFeatures();



sub new
{
  my $classname = shift;

  my %plotoptions = ();
  if(@_)
  {
    if(ref $_[0])
    {
      if(@_ != 1)
      {
        barf "PDL::Graphics::Gnuplot->new() got a ref as a first argument and has OTHER arguments. Don't know what to do";
      }

      %plotoptions = %{$_[0]};
    }
    else
    { %plotoptions = @_; }
  }

  if( my @badKeys = grep {!defined $plotOptionsSet{$_}} keys %plotoptions )
  {
    barf "PDL::Graphics::Gnuplot->new() got option(s) that were NOT a plot option: (@badKeys)";
  }

  my $pipes  = startGnuplot( $plotoptions{dump} );

  my $this = {%$pipes, # %$this is built on top of %$pipes
              options  => \%plotoptions,
              t0       => [gettimeofday]};
  bless($this, $classname);

  _logEvent($this, "startGnuplot() finished");


  # the plot options affect all the plots made by this object, so I can set them
  # now
  _safelyWriteToPipe($this, parseOptions(\%plotoptions));

  return $this;


  sub startGnuplot
  {
    my $dump = shift;
    return {in => \*STDOUT} if($dump);

    my @options = $gnuplotFeatures{persist} ? qw(--persist) : ();

    my $in  = gensym();
    my $err = gensym();

    my $pid =
      open3($in, undef, $err, 'gnuplot', @options)
        or die "Couldn't run the 'gnuplot' backend";

    return {in          => $in,
            err         => $err,
            errSelector => IO::Select->new($err),
            pid         => $pid};
  }

  sub parseOptions
  {
    my $options = shift;

    # set some defaults
    # plot with lines and points by default
    $options->{globalwith} = 'linespoints' unless defined $options->{globalwith};

    # make sure I'm not passed invalid combinations of options
    {
      if ( $options->{'3d'} )
      {
        if ( defined $options->{y2min} || defined $options->{y2max} )
        { barf "'3d' does not make sense with 'y2'...\n"; }

        if ( !$gnuplotFeatures{equal_3d} && (defined $options->{square_xy} || defined $options->{square} ) )
        {
          warn "Your gnuplot doesn't support square aspect ratios for 3D plots, so I'm ignoring that";
          delete $options->{square_xy};
          delete $options->{square};
        }
      }
      else
      {
        if ( defined $options->{square_xy} )
        { barf "'square'_xy only makes sense with '3d'\n"; }
      }
    }


    my $cmd   = '';

    # grid on by default
    if( !$options->{nogrid} )
    { $cmd .= "set grid\n"; }

    # set the plot bounds
    {
      # If a bound isn't given I want to set it to the empty string, so I can communicate it simply
      # to gnuplot
      $options->{xmin}  = '' unless defined $options->{xmin};
      $options->{xmax}  = '' unless defined $options->{xmax};
      $options->{ymin}  = '' unless defined $options->{ymin};
      $options->{ymax}  = '' unless defined $options->{ymax};
      $options->{y2min} = '' unless defined $options->{y2min};
      $options->{y2max} = '' unless defined $options->{y2max};
      $options->{zmin}  = '' unless defined $options->{zmin};
      $options->{zmax}  = '' unless defined $options->{zmax};
      $options->{cbmin} = '' unless defined $options->{cbmin};
      $options->{cbmax} = '' unless defined $options->{cbmax};

      # if any of the ranges are given, set the range
      $cmd .= "set xrange  [$options->{xmin} :$options->{xmax} ]\n" if length( $options->{xmin}  . $options->{xmax} );
      $cmd .= "set yrange  [$options->{ymin} :$options->{ymax} ]\n" if length( $options->{ymin}  . $options->{ymax} );
      $cmd .= "set zrange  [$options->{zmin} :$options->{zmax} ]\n" if length( $options->{zmin}  . $options->{zmax} );
      $cmd .= "set cbrange [$options->{cbmin}:$options->{cbmax}]\n" if length( $options->{cbmin} . $options->{cbmax} );
      $cmd .= "set y2range [$options->{y2min}:$options->{y2max}]\n" if length( $options->{y2min} . $options->{y2max} );
    }

    # set the curve labels, titles
    {
      $cmd .= "set xlabel  \"$options->{xlabel }\"\n" if defined $options->{xlabel};
      $cmd .= "set ylabel  \"$options->{ylabel }\"\n" if defined $options->{ylabel};
      $cmd .= "set zlabel  \"$options->{zlabel }\"\n" if defined $options->{zlabel};
      $cmd .= "set y2label \"$options->{y2label}\"\n" if defined $options->{y2label};
      $cmd .= "set title   \"$options->{title  }\"\n" if defined $options->{title};
    }

    # handle a requested square aspect ratio
    {
      # set a square aspect ratio. Gnuplot does this differently for 2D and 3D plots
      if ( $options->{'3d'})
      {
        if    ($options->{square})    { $cmd .= "set view equal xyz\n"; }
        elsif ($options->{square_xy}) { $cmd .= "set view equal xy\n" ; }
      }
      else
      {
        if( $options->{square} ) { $cmd .= "set size ratio -1\n"; }
      }
    }

    # handle 'hardcopy'. This simply ties in to 'output' and 'terminal', handled
    # later
    {
      if ( defined $options->{hardcopy})
      {
        # 'hardcopy' is simply a shorthand for 'terminal' and 'output', so they
        # can't exist together
        if(defined $options->{terminal} || defined $options->{output} )
        {
          barf <<EOM;
The 'hardcopy' option can't coexist with either 'terminal' or 'output'.  If the
defaults are acceptable, use 'hardcopy' only, otherwise use 'terminal' and
'output' to get more control.
EOM
        }

        my $outputfile = $options->{hardcopy};
        my ($outputfileType) = $outputfile =~ /\.(eps|ps|pdf|png)$/;
        if (!$outputfileType)
        { barf "Only .eps, .ps, .pdf and .png hardcopy output supported\n"; }

        my %terminalOpts =
          ( eps  => 'postscript solid color enhanced eps',
            ps   => 'postscript solid color landscape 10',
            pdf  => 'pdf solid color font ",10" size 11in,8.5in',
            png  => 'png size 1280,1024' );

        $options->{terminal} = $terminalOpts{$outputfileType};
        $options->{output}   = $outputfile;
      }

      if( defined $options->{terminal} && !defined $options->{output} )
      {
        print STDERR <<EOM;
Warning: defined gnuplot terminal, but NOT an output file. Is this REALLY what you want?
EOM
      }
    }


    # add the extra global options
    {
      if($options->{extracmds})
      {
        # if there's a single extracmds option, put it into a 1-element list to
        # make the processing work
        if(!ref $options->{extracmds} )
        { $options->{extracmds} = [$options->{extracmds}]; }

        foreach (@{$options->{extracmds}})
        { $cmd .= "$_\n"; }
      }
    }

    return $cmd;
  }
}

sub DESTROY
{
  my $this = shift;

  # if we're stuck on a checkpoint, "exit" won't work, so I just kill the
  # child gnuplot process
  if( defined $this->{pid})
  {
    if( $this->{checkpoint_stuck} )
    {
      kill 'TERM', $this->{pid};
    }
    else
    {
      _printGnuplotPipe( $this, "exit\n" );
    }

    waitpid( $this->{pid}, 0 ) ;
  }
}

# the main API function to generate a plot. Input arguments are a bunch of
# piddles optionally preceded by a bunch of options for each curve. See the POD
# for details
sub plot
{
  barf( "Plot called with no arguments") unless @_;

  my $this;

  if(defined ref $_[0] && ref $_[0] eq 'PDL::Graphics::Gnuplot')
  {
    # I called this as an object-oriented method. First argument is the
    # object. I already got the plot options in the constructor, so I don't need
    # to get them again.
    $this = shift;
  }
  else
  {
    # plot() called as a global function, NOT as a method. The initial arguments
    # can be the plot options (hashrefs or inline). I keep trying to parse the
    # initial arguments as plot options until I run out
    my $plotOptions = {};

    while(1)
    {
      if (defined ref $_[0] && ref $_[0] eq 'HASH')
      {
        # arg is a hash. Is it plot options or curve options?
        my $NmatchedPlotOptions = grep {defined $plotOptionsSet{$_}} keys %{$_[0]};

        last if $NmatchedPlotOptions == 0; # not plot options, so done scanning

        if( $NmatchedPlotOptions != scalar keys %{$_[0]} )
        { barf "Plot option hash has some non-plot options"; }

        # grab all the plot options
        my $newPlotOptions = shift;
        foreach my $key (keys %$newPlotOptions)
        { $plotOptions->{$key} = $newPlotOptions->{$key}; }
      }
      else
      {
        # arg is NOT a hashref. It could be an inline hash. I grab a hash pair
        # if it's plot options
        last unless @_ >= 2 && $plotOptionsSet{$_[0]};

        my $key = shift;
        my $val = shift;
        $plotOptions->{$key} = $val;
      }
    }

    $this = $globalPlot = PDL::Graphics::Gnuplot->new($plotOptions);
  }

  my $plotOptions = $this->{options};

  # I split my data-to-plot into similarly-styled chunks
  # pieces of data we're plotting. Each chunk has a similar style
  my ($chunks, $Ncurves) = parseArgs($plotOptions->{'3d'}, @_);


  if( scalar @$chunks == 0)
  { barf "plot() was not given any data"; }


  # I'm now ready to send the plot command. If the plot command fails, I'll get
  # an error message; if it succeeds, gnuplot will sit there waiting for data. I
  # don't want to have a timeout waiting for the error message, so I try to run
  # the plot command to see if it works. I make a dummy plot into the 'dumb'
  # terminal, and then _checkpoint() for errors.  To make this quick, the test
  # plot command contains the minimum number of data points
  my ($plotcmd, $testplotcmd, $testplotdata) =
    plotcmd( $chunks, @{$plotOptions}{qw(3d binary globalwith)} );

  testPlotcmd($this, $testplotcmd, $testplotdata);

  # tests ok. Now set the terminal and actually make the plot!
  if(defined $this->{options}{terminal})
  { _safelyWriteToPipe($this, "set terminal $this->{options}{terminal}\n", 'terminal'); }

  if(defined $this->{options}{output})
  { _safelyWriteToPipe($this, "set output \"$this->{options}{output}\"\n", 'output'); }

  # all done. make the plot
  _printGnuplotPipe( $this, "$plotcmd\n");

  foreach my $chunk(@$chunks)
  {
    # In order for the PDL threading to work, I need at least one dimension. Add
    # it where needed. pdl(5) has 0 dimensions, for instance. I really want
    # something like "plot(5, pdl(3,4,5,3,4))" to work; It doesn't right
    # now. This map() makes "plot(pdl(3), pdl(5))" work. This is good for
    # completeness, but not really all that interesting
    my @data = map {$_->ndims == 0 ? $_->dummy(0) : $_} @{$chunk->{data}};

    my $tuplesize = scalar @data;
    eval( "_writedata_$tuplesize" . '(@data, $this, $plotOptions->{binary})');
  }

  # read and report any warnings that happened during the plot
  _checkpoint($this, 'printwarnings');







  # generates the gnuplot command to generate the plot. The curve options are parsed here
  sub plotcmd
  {
    my ($chunks, $is3d, $isbinary, $globalwith) = @_;

    my $basecmd = '';

    # if anything is to be plotted on the y2 axis, set it up
    if( grep {my $chunk = $_; grep {$_->{y2}} @{$chunk->{options}}} @$chunks)
    {
      if ( $is3d )
      { barf "3d plots don't have a y2 axis"; }

      $basecmd .= "set ytics nomirror\n";
      $basecmd .= "set y2tics\n";
    }

    if($is3d) { $basecmd .= 'splot '; }
    else      { $basecmd .= 'plot ' ; }


    my @plotChunkCmd;
    my @plotChunkCmdMinimal; # same as above, but with a single data point per plot only
    my $testData = '';       # data to make a minimal plot

    foreach my $chunk (@$chunks)
    {
      my @optionCmds =
        map { optioncmd($_, $globalwith) } @{$chunk->{options}};

      if( $isbinary )
      {
        # I get 2 formats: one real, and another to test the plot cmd, in case it
        # fails. The test command is the same, but with a minimal point count. I
        # also get the number of bytes in a single data point here
        my ($format, $formatMinimal) = binaryFormatcmd($chunk);
        my $Ntestbytes_here          = getNbytes_tuple($chunk);

        push @plotChunkCmd,        map { "'-' $format $_"     }    @optionCmds;
        push @plotChunkCmdMinimal, map { "'-' $formatMinimal $_" } @optionCmds;

        # If there was an error, these whitespace commands will simply do
        # nothing. If there was no error, these are data that will be plotted in
        # some manner. I'm not actually looking at this plot so I don't care
        # what it is. Note that I'm not making assumptions about how long a
        # newline is (perl docs say it could be 0 bytes). I'm printing as many
        # spaces as the number of bytes that I need, so I'm potentially doubling
        # or even tripling the amount of needed data. This is OK, since gnuplot
        # will simply ignore the tail.
        $testData .= " \n" x ($Ntestbytes_here * scalar @optionCmds);
      }
      else
      {
        # I'm using ascii to talk to gnuplot, so the minimal and "normal" plot
        # commands are the same (point count is not in the plot command)
        push @plotChunkCmd, map { "'-' $_" } @optionCmds;

        my $testData_curve = $testdataunit_ascii x $chunk->{tuplesize} . "\n" . "e\n";
        $testData .= $testData_curve x scalar @optionCmds;
      }
    }

    # the command to make the plot and to test the plot
    my $cmd        = $basecmd . join(',', @plotChunkCmd);
    my $cmdMinimal = @plotChunkCmdMinimal ?
      $basecmd . join(',', @plotChunkCmdMinimal) :
      $cmd;

    return ($cmd, $cmdMinimal, $testData);



    # parses a curve option
    sub optioncmd
    {
      my $option     = shift;
      my $globalwith = shift;

      my $cmd = '';

      if( defined $option->{legend} )
      { $cmd .= "title \"$option->{legend}\" "; }
      else
      { $cmd .= "notitle "; }

      # use the given per-curve 'with' style if there is one. Otherwise fall
      # back on the global
      my $with = $option->{with} || $globalwith;

      $cmd .= "with $with " if $with;
      $cmd .= "axes x1y2 "  if $option->{y2};

      return $cmd;
    }

    sub binaryFormatcmd
    {
      # I make 2 formats: one real, and another to test the plot cmd, in case it
      # fails
      my $chunk = shift;

      my $tuplesize  = $chunk->{tuplesize};
      my $recordSize = $chunk->{data}[0]->dim(0);

      my $format = "binary record=$recordSize format=\"";
      $format .= '%double' x $tuplesize;
      $format .= '"';

      # When plotting in binary, gnuplot gets confused if I don't explicitly
      # tell it the tuplesize. It's got its own implicit-tuples logic that I
      # don't want kicking in. As an example, the following simple plot doesn't
      # work in binary without this extra line:
      # plot3d(binary => 1,
      #        with => 'image', sequence(5,5));
      $format .= ' using ' . join(':', 1..$tuplesize);

      # to test the plot I plot a single record
      my $formatTest = $format;
      $formatTest =~ s/record=\d+/record=1/;

      return ($format, $formatTest);
    }

    sub getNbytes_tuple
    {
      my $chunk = shift;
      # assuming sizeof(double)==8
      return 8 * $chunk->{tuplesize};
    }
  }

  sub parseArgs
  {
    # Here I parse the plot() arguments.  Each chunk of data to plot appears in
    # the argument list as plot(options, options, ..., data, data, ....). The
    # options are a hashref, an inline hash or can be absent entirely. THE
    # OPTIONS ARE ALWAYS CUMULATIVELY DEFINED ON TOP OF THE PREVIOUS SET OF
    # OPTIONS (except the legend)
    # The data arguments are one-argument-per-tuple-element.
    my $is3d = shift;
    my @args = @_;

    # options are cumulative except the legend (don't want multiple plots named
    # the same). This is a hashref that contains the accumulator
    my $lastOptions = {};

    my @chunks;
    my $Ncurves  = 0;
    my $argIndex = 0;
    while($argIndex <= $#args)
    {
      # First, I find and parse the options in this chunk
      my $nextDataIdx = first {ref $args[$_] && ref $args[$_] eq 'PDL'} $argIndex..$#args;
      last if !defined $nextDataIdx; # no more data. done.

      # I do not reuse the curve legend, since this would result it multiple
      # curves with the same name
      delete $lastOptions->{legend};

      my %chunk;
      if( $nextDataIdx > $argIndex )
      {
        $chunk{options} = parseOptionsArgs($lastOptions, @args[$argIndex..$nextDataIdx-1]);

        # make sure I know what to do with all the options
        foreach my $option (@{$chunk{options}})
        {
          if (my @badKeys = grep {!defined $curveOptionsSet{$_}} keys %$option)
          {
            barf "plot() got some unknown curve options: (@badKeys)";
          }
        }
      }
      else
      {
        # No options given for this chunk, so use the last ones
        $chunk{options} = [ dclone $lastOptions ];
      }

      # I now have the options for this chunk. Let's grab the data
      $argIndex         = $nextDataIdx;
      my $nextOptionIdx = first {!ref $args[$_] || ref $args[$_] ne 'PDL'} $argIndex..$#args;
      $nextOptionIdx = @args unless defined $nextOptionIdx;

      my $tuplesize    = getTupleSize($is3d, $chunk{options});
      my $NdataPiddles = $nextOptionIdx - $argIndex;

      # If I have more data piddles that I need, use only what I need now, and
      # use the rest for the next curve
      if($NdataPiddles > $tuplesize)
      {
        $nextOptionIdx = $argIndex + $tuplesize;
        $NdataPiddles  = $tuplesize;
      }

      my @dataPiddles   = @args[$argIndex..$nextOptionIdx-1];

      if($NdataPiddles < $tuplesize)
      {
        # I got fewer data elements than I expected

        if(!$is3d && $NdataPiddles+1 == $tuplesize)
        {
          # A 2D plot is one data element short. Fill in a sequential domain
          # 0,1,2,...
          unshift @dataPiddles, sequence($dataPiddles[0]->dim(0));
        }
        elsif($is3d && $NdataPiddles+2 == $tuplesize)
        {
          # a 3D plot is 2 elements short. Use a grid as a domain
          my @dims = $dataPiddles[0]->dims();
          if(@dims < 1)
          { barf "plot() tried to build a 2D implicit domain, but the first data piddle is too small"; }

          # grab the first 2 dimensions to build the x-y domain
          splice @dims, 2;
          my $x = zeros(@dims)->xvals->clump(2);
          my $y = zeros(@dims)->yvals->clump(2);
          unshift @dataPiddles, $x, $y;

          # un-grid the data-to plot to match the new domain
          foreach my $data(@dataPiddles)
          { $data = $data->clump(2); }
        }
        else
        { barf "plot() needed $tuplesize data piddles, but only got $NdataPiddles"; }
      }

      $chunk{data}      = \@dataPiddles;
      $chunk{tuplesize} = $tuplesize;
      $chunk{Ncurves}   = countCurvesAndValidate(\%chunk);
      $Ncurves += $chunk{Ncurves};

      push @chunks, \%chunk;

      $argIndex = $nextOptionIdx;
    }

    return (\@chunks, $Ncurves);




    sub parseOptionsArgs
    {
      # my options are cumulative, except the legend. This variable contains the accumulator
      my $options = shift;

      # I now have my options arguments. Each curve is described by a hash
      # (reference or inline). To have separate options for each curve, I use an
      # ref to an array of hashrefs
      my @optionsArgs = @_;

      # the options for each curve go here
      my @curveOptions = ();

      my $optionArgIdx = 0;
      while ($optionArgIdx < @optionsArgs)
      {
        my $optionArg = $optionsArgs[$optionArgIdx];

        if (ref $optionArg)
        {
          if (ref $optionArg eq 'HASH')
          {
            # add this hashref to the options
            @{$options}{keys %$optionArg} = values %$optionArg;
            push @curveOptions, dclone($options);

            # I do not reuse the curve legend, since this would result it multiple
            # curves with the same name
            delete $options->{legend};
          }
          else
          {
            barf "plot() got a reference to a " . ref( $optionArg) . ". I can only deal with HASHes and ARRAYs";
          }

          $optionArgIdx++;
        }
        else
        {
          my %unrefedOptions;
          do
          {
            $optionArg = $optionsArgs[$optionArgIdx];

            # this is a scalar. I interpret a pair as key/value
            if ($optionArgIdx+1 == @optionsArgs)
            { barf "plot() got a lone scalar argument $optionArg, where a key/value was expected"; }

            $options->{$optionArg} = $optionsArgs[++$optionArgIdx];
            $optionArgIdx++;
          } while($optionArgIdx < @optionsArgs && !ref $optionsArgs[$optionArgIdx]);
          push @curveOptions, dclone($options);

          # I do not reuse the curve legend, since this would result it multiple
          # curves with the same name
          delete $options->{legend};
        }

      }

      return \@curveOptions;
    }

    sub countCurvesAndValidate
    {
      my $chunk = shift;

      # Make sure the domain and ranges describe the same number of data points
      my $data = $chunk->{data};
      foreach (1..$#$data)
      {
        my $dim0 = $data->[$_  ]->dim(0);
        my $dim1 = $data->[$_-1]->dim(0);
        if( $dim0 != $dim1 )
        { barf "plot() was given mismatched tuples to plot. $dim0 vs $dim1"; }
      }

      # I now make sure I have exactly one set of curve options per curve
      my $Ncurves = countCurves($data);
      my $Noptions = scalar @{$chunk->{options}};

      if($Noptions > $Ncurves)
      { barf "plot() got $Noptions options but only $Ncurves curves. Not enough curves"; }
      elsif($Noptions < $Ncurves)
      {
        # I have more curves then options. I pad the option list with the last
        # option, removing the legend
        my $lastOption = dclone $chunk->{options}[-1];
        delete $lastOption->{legend};
        push @{$chunk->{options}}, ($lastOption) x ($Ncurves - $Noptions);
      }

      return $Ncurves;



      sub countCurves
      {
        # compute how many curves have been passed in, assuming things thread

        my $data = shift;

        my $N = 1;

        # I need to look through every dimension to check that things can thread
        # and then to compute how many threads there will be. I skip the first
        # dimension since that's the data points, NOT separate curves
        my $maxNdims = List::Util::max map {$_->ndims} @$data;
        foreach my $dimidx (1..$maxNdims-1)
        {
          # in a particular dimension, there can be at most 1 non-1 unique
          # dimension. Otherwise threading won't work.
          my $nonDegenerateDim;

          foreach (@$data)
          {
            my $dim = $_->dim($dimidx);
            if($dim != 1)
            {
              if(defined $nonDegenerateDim && $nonDegenerateDim != $dim)
              {
                barf "plot() was given non-threadable arguments. Got a dim of size $dim, when I already saw size $nonDegenerateDim";
              }
              else
              {
                $nonDegenerateDim = $dim;
              }
            }
          }

          # this dimension checks out. Count up the curve contribution
          $N *= $nonDegenerateDim if $nonDegenerateDim;
        }

        return $N;
      }
    }

    sub getTupleSize
    {
      my $is3d    = shift;
      my $options = shift;

      # I have a list of options for a set of curves in a chunk. Inside a chunk
      # the tuple set MUST be the same. I.e. I can have 2d data in one chunk and
      # 3d data in another, but inside a chunk it MUST be consistent
      my $size;
      foreach my $option (@$options)
      {
        my $sizehere;

        if ($option->{tuplesize})
        {
          # if we have a given tuple size, just use it
          $sizehere = $option->{tuplesize};
        }
        else
        {
          $sizehere = $is3d ? 3 : 2; # given nothing else, use ONLY the geometrical plotting
        }

        if(!defined $size)
        { $size = $sizehere;}
        else
        {
          if($size != $sizehere)
          {
            barf "plot() tried to change tuplesize in a chunk: $size vs $sizehere";
          }
        }
      }

      return $size;
    }
  }

  sub testPlotcmd
  {
    # I test the plot command by making a dummy plot with the test command.
    my ($this, $testplotcmd, $testplotdata) = @_;

    _printGnuplotPipe( $this, "set terminal push\n" );
    _printGnuplotPipe( $this, "set output\n" );
    _printGnuplotPipe( $this, "set terminal dumb\n" );

    # I send a test plot command. Gnuplot implicitly uses && if multiple
    # commands are present on the same line. Thus if I see the post-plot print
    # in the output, I know the plot command succeeded
    my $postTestplotCheckpoint   = 'xxxxxxx Plot succeeded xxxxxxx';
    my $print_postTestCheckpoint = "; print \"$postTestplotCheckpoint\"";
    _printGnuplotPipe( $this, "$testplotcmd$print_postTestCheckpoint\n" );
    _printGnuplotPipe( $this, $testplotdata );

    my $checkpointMessage = _checkpoint($this, 'ignore_invalidcommand');

    if(defined $checkpointMessage && $checkpointMessage !~ /^$postTestplotCheckpoint/m)
    {
      # don't actually print out the checkpoint message
      $checkpointMessage =~ s/$print_postTestCheckpoint//;

      # The checkpoint message does not contain the post-plot checkpoint. This
      # means gnuplot decided that the plot command failed.
      barf "Gnuplot error: \"\n$checkpointMessage\n\" while sending plotcmd \"$testplotcmd\"";
    }

    _printGnuplotPipe( $this, "set terminal pop\n" );
  }

  # syncronizes the child and parent processes. After _checkpoint() returns, I
  # know that I've read all the data from the child. Extra data that represents
  # errors is returned. Warnings are explicitly stripped out
  sub _checkpoint
  {
    my $this   = shift;
    my $pipeerr = $this->{err};

    # string containing various options to this function
    my $flags = shift;

    # I have no way of knowing if the child process has sent its error data
    # yet. It may be that an error has already occurred, but the message hasn't
    # yet arrived. I thus print out a checkpoint message and keep reading the
    # child's STDERR pipe until I get that message back. Any errors would have
    # been printed before this
    my $checkpoint = "xxxxxxx Syncronizing gnuplot i/o xxxxxxx";

    _printGnuplotPipe( $this, "print \"$checkpoint\"\n" );


    # if no error pipe exists, we can't check for errors, so we're done. Usually
    # happens if($dump)
    return unless defined $pipeerr;

    my $fromerr = '';

    do
    {
      # if no data received in 5 seconds, the gnuplot process is stuck. This
      # usually happens if the gnuplot process is not in a command mode, but in
      # a data-receiving mode. I'm careful to avoid this situation, but bugs in
      # this module and/or in gnuplot itself can make this happen

      _logEvent($this, "Trying to read from gnuplot");

      if( $this->{errSelector}->can_read(5) )
      {
        # read a byte into the tail of $fromerr. I'd like to read "as many bytes
        # as are available", but I don't know how to this in a very portable way
        # (I just know there will be windows users complaining if I simply do a
        # non-blocking read). Very little data will be coming in anyway, so
        # doing this a byte at a time is an irrelevant inefficiency
        my $byte;
        sysread $pipeerr, $byte, 1;
        $fromerr .= $byte;

        _logEvent($this, "Read byte '$byte' (0x" . unpack("H2", $byte) . ") from gnuplot child process");
      }
      else
      {
        _logEvent($this, "Gnuplot read timed out");

        $this->{checkpoint_stuck} = 1;

        barf <<EOM;
Gnuplot process no longer responding. This is likely a bug in PDL::Graphics::Gnuplot
and/or gnuplot itself. Please report this as a PDL::Graphics::Gnuplot bug.
EOM
      }
    } until $fromerr =~ /\s*(.*?)\s*$checkpoint.*$/ms;

    $fromerr = $1;

    my $warningre = qr{^(?:Warning:\s*(.*?)\s*$)\n?}m;

    if(defined $flags && $flags =~ /printwarnings/)
    {
      while($fromerr =~ m/$warningre/gm)
      { print STDERR "Gnuplot warning: $1\n"; }
    }


    # I've now read all the data up-to the checkpoint. Strip out all the warnings
    $fromerr =~ s/$warningre//gm;

    # if asked, get rid of all the "invalid command" errors. This is useful if
    # I'm testing a plot command and I want to ignore the errors caused by the
    # test data bein sent to gnuplot as a command. The plot command itself will
    # never be invalid, so this doesn't actually mask out any errors
    if(defined $flags && $flags =~ /ignore_invalidcommand/)
    {
      $fromerr =~ s/^gnuplot>\s*(?:$testdataunit_ascii|e\b).*$ # report of the actual invalid command
                    \n^\s+\^\s*$                               # ^ mark pointing to where the error happened
                    \n^.*invalid\s+command.*$//xmg;            # actual 'invalid command' complaint
    }

    # strip out all the leading/trailing whitespace
    $fromerr =~ s/^\s*//;
    $fromerr =~ s/\s*$//;

    return $fromerr;
  }
}

# these are convenience wrappers for plot()
sub plot3d
{
  plot('3d' => 1, @_);
}

sub plotlines
{
  plot(globalwith => 'lines', @_);
}

sub plotpoints
{
  plot(globalwith => 'points', @_);
}


# subroutine to write the columns of some piddles into a gnuplot stream. This
# assumes the last argument is a file handle. Generally you should NOT be using
# this directly at all; it's just used to define the threading-aware routines
sub _wcols_gnuplot
{
  my $isbinary = pop @_;
  my $this     = pop @_;

  if( $isbinary)
  {
    # this is not efficient right now. I should do this in C so that I don't
    # have to physical-ize the piddles and so that I can keep the original type
    # instead of converting to double
    _printGnuplotPipe( $this, ${ cat(@_)->transpose->double->get_dataref } );
  }
  else
  {
    _wcolsGnuplotPipe( $this, @_ );
    _printGnuplotPipe( $this, "e\n" );
  }
};


sub _printGnuplotPipe
{
  my $this   = shift;
  my $string = shift;

  my $pipein = $this->{in};
  print $pipein $string;

  my $len = length $string;
  _logEvent($this,
            "Sent to child process $len bytes ==========\n" . $string . "\n=========================" );
}

sub _wcolsGnuplotPipe
{
  my $this   = shift;

  my $pipein = $this->{in};
  wcols @_, $pipein;

  if( $this->{options}{log} )
  {
    my $string;
    open FH, '>', \$string or barf "Couldn't open filehandle into string";
    wcols @_, *FH;
    close FH;

    _logEvent($this,
              "Sent to child process ==========\n" . $string . "\n=========================" );
  }
}

sub _safelyWriteToPipe
{
  my ($this, $string, $flags) = @_;

  foreach my $line(split('\s*?\n+\s*?', $string))
  {
    next unless $line;

    barfOnDisallowedCommands($line, $flags);

    _printGnuplotPipe( $this, "$line\n" );

    if( my $errorMessage = _checkpoint($this, 'printwarnings') )
    {
      barf "Gnuplot error: \"\n$errorMessage\n\" while sending line \"$line\"";
    }
  }

  sub barfOnDisallowedCommands
  {
    my $line  = shift;
    my $flags = shift;

    # I use STDERR as the backchannel, so I don't allow any "set print"
    # commands, since those can disable that
    if ( $line =~ /^(?: .*;)?       # optionally wait for a semicolon
                   \s*
                   set\s+print\b/x )
    {
      barf "Please don't 'set print' since I use gnuplot's STDERR for error detection";
    }

    if ( $line =~ /^(?: .*;)?       # optionally wait for a semicolon
                   \s*
                   print\b/x )
    {
      barf "Please don't ask gnuplot to 'print' anything since this can confuse my error detection";
    }

    if ( $line =~ /^(?: .*;)?       # optionally wait for a semicolon
                   \s*
                   set\s+terminal\b/x )
    {
      if( !defined $flags || $flags !~ /terminal/ )
      {
        barf "Please do not 'set terminal' manually. Use the 'terminal' plot option instead";
      }
    }

    if ( $line =~ /^(?: .*;)?       # optionally wait for a semicolon
                   \s*
                   set\s+output\b/x )
    {
      if( !defined $flags || $flags !~ /output/ )
      {
        barf "Please do not 'set output' manually. Use the 'output' plot option instead";
      }
    }
  }
}

# I generate a bunch of PDL definitions such as
# _writedata_2(x1(n), x2(n)), NOtherPars => 2
# The last 2 arguments are (pipe, isbinary)
# 20 tuples per point sounds like plenty. The most complicated plots Gnuplot can
# handle probably max out at 5 or so
for my $n (2..20)
{
  my $def = "_writedata_$n(" . join( ';', map {"x$_(n)"} 1..$n) . "), NOtherPars => 2";
  thread_define $def, over \&_wcols_gnuplot;
}


sub _getGnuplotFeatures
{
  # I could use qx{} to talk to gnuplot here, but I don't want to use a
  # tty. gnuplot messes with the tty settings where it should NOT. For example
  # it turns on the local echo

  my %featureSet;

  # first, I run 'gnuplot --help' to extract all the cmdline options as features
  {
    my $in  = '';
    my $out = '';
    my $err = '';
    eval{ IPC::Run::run([qw(gnuplot --help)], \$in, \$out, \$err) };
    barf $@ if $@;

    foreach ( "$out\n$err\n" =~ /--([a-zA-Z0-9_]+)/g )
    {
      $featureSet{$_} = 1;
    }
  }

  # then I try to set a square aspect ratio for 3D to see if it works
  {
    my $in = <<EOM;
set view equal
exit
EOM
    my $out = '';
    my $err = '';


    eval{ IPC::Run::run(['gnuplot'], \$in, \$out, \$err) };
    barf $@ if $@;

    # no output if works; some output if error
    $featureSet{equal_3d} = 1 unless ($out || $err);
  }


  return %featureSet;
}

sub _logEvent
{
  my $this  = shift;
  my $event = shift;

  return unless $this->{options}{log}; # only log when asked

  my $t1 = tv_interval( $this->{t0}, [gettimeofday] );

  # $event can have '%', so I don't printf it
  my $logline = sprintf "==== PDL::Graphics::Gnuplot PID $this->{pid} at t=%.4f:", $t1;
  print STDERR "$logline $event\n";
}

1;
