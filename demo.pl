#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';

use PDL;
use PDL::NiceSlice;
use PDL::Graphics::Gnuplot qw(plot plot3d);


use feature qw(say);

# data I use for 2D testing
my $x = sequence(21) - 10;

# data I use for 3D testing
my $th   = zeros(30)->           xlinvals( 0,          3.14159*2);
my $ph   = zeros(30)->transpose->ylinvals( -3.14159/2, 3.14159/2);
my $x_3d = PDL::flat( cos($ph)*cos($th));
my $y_3d = PDL::flat( cos($ph)*sin($th));
my $z_3d = PDL::flat( sin($ph) * $th->ones );


#################################
# Now the tests!
#################################

# first, some very basic stuff. Testing implicit domains, multiple curves in
# arguments, packed in piddles, etc
plot($x**2);
plot(-$x, $x**3);
plot(-$x, $x**3,
     $x,  $x**2);
plot(PDL::cat($x**2, $x**3));
plot(-$x,
     PDL::cat($x**2, $x**3));

# some more varied plotting, using the object-oriented interface
{
  my $plot = PDL::Graphics::Gnuplot->new(binary => 1,
                                         globalwith => 'linespoints', xmin => -10,
                                         title => 'Error bars and other things');

  $plot->plot(with => 'lines lw 4',
              y2 => 1, legend => 'a parabola',
              PDL::cat($x, $x*2, $x*3), $x**2 - 300,

              y2 => 0,
              with => 'xyerrorbars', tuplesize => 4,
              $x**2 * 10, $x**2/40, $x**2/2, # implicit domain

              {with => '', legend => 'cubic', tuplesize => 2},
              {legend => 'shifted cubic'},
              $x, PDL::cat($x**3, $x**3 - 100) );
}

# a way to control the point size
plot(binary => 1,
     {cbmin => -600, cbmax => 600}, {with => 'points pointtype 7 pointsize variable palette', tuplesize => 4},
     $x**2, abs($x)/2, $x*50);

################################
# some 3d stuff
################################

# plot a sphere
plot3d( binary => 1,
        globalwith => 'points', title  => 'sphere',
        square => 1,

        {legend => 'sphere'}, $x_3d, $y_3d, $z_3d,
      );

# sphere, ellipse together
plot3d( binary => 1,
        globalwith => 'points', title  => 'sphere, ellipse',
        square => 1,

        {legend => 'sphere'}, {legend => 'ellipse'},
        $x_3d->cat($x_3d*2),
        $y_3d->cat($y_3d*2), $z_3d );



# similar, written to a png
plot3d (binary => 1,
        globalwith => 'points', title    => 'sphere, ellipse',
        square   => 1,
        hardcopy => 'spheres.png',

        {legend => 'sphere'}, {legend => 'ellipse'},
        $x_3d->cat($x_3d*2), $y_3d->cat($y_3d*2), $z_3d );


# some paraboloids plotted on an implicit 2D domain
{
  my $xy = zeros(21,21)->ndcoords - pdl(10,10);
  my $z = inner($xy, $xy);

  my $xy_half = zeros(11,11)->ndcoords;
  my $z_half = inner($xy_half, $xy_half);

  plot3d( binary => 1,
          globalwith => 'points', title  => 'gridded paraboloids',
          {legend => 'zplus'} , {legend=>'zminus'}, $z->cat(-$z),
          {legend => 'zplus2'}, $z*2);
}

# 3d, variable color, variable pointsize
{
 my $pi   = 3.14159;
 my $theta = zeros(200)->xlinvals(0, 6*$pi);
 my $z     = zeros(200)->xlinvals(0, 5);

 plot3d( binary => 1,
         title => 'double helix',

         { with => 'points pointsize variable pointtype 7 palette', tuplesize => 5,
           legend => 'spiral 1'},
         { legend => 'spiral 2' },

         # 2 sets of x, y, z:
         cos($theta)->cat(-cos($theta)),
         sin($theta)->cat(-sin($theta)),
         $z,

         # pointsize, color
         0.5 + abs(cos($theta)), sin(2*$theta) );
}

# implicit domain heat map
{
  my $xy = zeros(21,21)->ndcoords - pdl(10,10);
  plot3d(binary => 1,
         title  => 'Paraboloid heat map',
         extracmds => 'set view map',
         with => 'image', inner($xy, $xy));
}

# same, but as a 2d plot, with a curve drawn on top for good measure
{
  my $xy = zeros(21,21)->ndcoords - pdl(10,10);
  my $x = zeros(100)->xlinvals(0, 20);
  plot(title  => 'Paraboloid heat map, 2D',
       xmin => 0, xmax => 20, ymin => 0, ymax => 20,
       tuplesize => 3, with => 'image', inner($xy, $xy),
       tuplesize => 2, with => 'lines', $x, 20*cos($x/20 * 3.14159/2) );
}



################################
# 2D implicit domain tests
################################
{
  my $xy = zeros(21,21)->ndcoords - pdl(10,10);
  my $x = $xy((0),:,:);
  my $z = sqrt(inner($xy, $xy));

  $xy = $xy(2:12,:);
  $x  = $x(2:12,:);
  $z  = $z(2:12,:);

  # single 3d matrix curve
  plot(title  => 'Single 3D matrix plot. Binary.', binary => 1,
       square => 1,
       tuplesize => 3, with => 'points palette pt 7',
       $z);

  # 4d matrix curve
  plot(title  => '4D matrix plot. Binary.', binary => 1,
       square => 1,
       tuplesize => 4, with => 'points palette ps variable pt 7',
       $z, $x);

  # 2 3d matrix curves
  plot(title  => '2 3D matrix plots. Binary.', binary => 1,
       square => 1,
       {tuplesize => 3, with => 'points palette pt 7'},
       {with => 'points ps variable pt 6'},
       $x->cat($z));

  # # Gnuplot doesn't support this
  # # 4d matrix curve
  # plot(title  => '4D matrix plot. ASCII.', binary => 0,
  #      square => 1,
  #      tuplesize => 4, with => 'points palette ps variable pt 7',
  #      $z, $x);

  # 2 3d matrix curves
  plot(title  => '2 3D matrix plots. ASCII.', binary => 0,
       square => 1,
       {tuplesize => 3, with => 'points palette pt 7'},
       {with => 'points ps variable pt 6'},
       $x->cat($z));
}

###################################
# fancy contours just because I can
###################################
{
  my $x = zeros(61,61)->xvals - 30;
  my $y = zeros(61,61)->yvals - 30;
  my $z = sin($x / 4) * $y;

  # single 3d matrix curve
  plot('3d' => 1,
       title  => 'matrix plot with contours',
       extracmds => [ 'set contours base',
                      'set cntrparam bspline',
                      'set cntrparam levels 15',
                      'unset grid',
                      'unset surface',
                      'set view 0,0'],
       square => 1,
       tuplesize => 3, with => 'image', $z,
       tuplesize => 3, with => 'lines', $z
      );
}


################################
# testing some error detection
################################

say STDERR "\n\n\n";
say STDERR "==== Testing error detection ====";
say STDERR 'I should complain about an invalid "with":';
say STDERR "=================================";
eval( <<'EOM' );
plot(with => 'bogusstyle', $x);
EOM
print STDERR $@ if $@;
say STDERR "=================================\n\n";


say STDERR 'PDL::Graphics::Gnuplot can detect I/O hangs. Here I ask for a delay, so I should detect this and quit after a few seconds:';
say STDERR "=================================";
eval( <<'EOM' );
  my $xy = zeros(21,21)->ndcoords - pdl(10,10);
  plot( extracmds => 'pause 10',
        sequence(5));
EOM
print STDERR $@ if $@;
say STDERR "=================================\n\n";
