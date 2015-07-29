# Plotter

Mac OS X app to plot numbers fed to it through standard input.

Usage:

    % python foo.py | Plotter

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

