# Plotter

Mac OS X app to plot numbers fed to it through standard input.

Usage:

    % python example.py | Plotter

The data must have one line per data point, and a data point can
have any number of values, separated by spaces or tabs:

    1.1 5 234
    1.2 4.9 254
    ...

Each column represents a series, which will be drawn horizontally in
a plot. For example, this program (see `example.py`):

    import math

    print "Sine*Exp\tCosine"

    t = 0
    while t < 20:
        print math.sin(t)*math.exp(-t*0.1), math.cos(t)
        t += 0.1

generates this plot:

![Screenshot of Plotter](screenshot.png)

You can specify a header as the first row. It is auto-detected by looking
for alphabetic characters. Header fields _must_ be separated by tabs.

    Growth\tAge\tDollars
    1.1 5 234
    1.2 4.9 254
    ...

The header will be used as series titles in the legend. Headers can
optionally specify comma-separated options in brackets:

    Growth [red]\tAge [hide]\tDollars [purple,right]
    1.1 5 234
    1.2 4.9 254
    ...

The options are:

- A color (`blue`, `brown`, `cyan`, `gray`, `green`, `magenta`, `orange`,
  `purple`, `red`, `white`, or `yellow`). If a color is unspecified, a default
  color is chosen.
- Whether to associate the series with the left axis (`left`) or right axis (`right`). The
  default is `left`. This can be useful if the plot contains values of different units
  or vastly different ranges.
- Whether to hide the series altogether (`hide`). This is useful if you want to omit the
  series from the plot without modifying your program much.
- Whether the series should be the domain (`domain`). If this flag is specified, then the
  series will be used for the horizontal axis. If missing, the domain will implicitly
  be the line number (starting with 1).
- Whether to display the derivative of the data (`derivative`). This can be specified multiple
  times to compute the second derivative, third derivative, and so on. For each derivative,
  the title in the legend has an apostrophe appended to it.

To actually run the binary from the command line, you'll have to add the build directory
to your path, copy the binary to a directory already in your path, or run it
directly from the build directory. For me the build location is something like
`/Users/lk/Library/Developer/Xcode/DerivedData/Plotter-btpwhghyeyiylxbuefmsxxunmfrc/Build/Products/Debug/Plotter.app/Contents/MacOS/Plotter`. I found this by temporarily adding this to
the top of the `main()` function:

    NSLog(@"%s", argv[0]);

and running the app in Xcode. Running the app this way hangs, since there's nothing
on the standard input, but it'll show you its full pathname.

# License

Copyright 2015 Lawrence Kesteloot

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

