#  File src/library/parallel/R/unix/pvec.R
#  Part of the R package, http://www.R-project.org
#
#  Copyright (C) 1995-2012 The R Core Team
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  http://www.r-project.org/Licenses/

### Derived from parallel version 2.16.0 by R Core Team
### Derived from multicore version 0.1-6 by Simon Urbanek

pvec <- function(v, FUN, ..., mc.set.seed = TRUE, mc.silent = FALSE,
                 mc.cores = getOption("mc.cores", 2L), mc.cleanup = TRUE)
{
    env <- parent.frame()
    cores <- as.integer(mc.cores)
    if(cores < 1L) stop("'mc.cores' must be >= 1")
    if(cores == 1L) return(FUN(v, ...))

    if(mc.set.seed) mc.reset.stream()

    n <- length(v)
    si <- splitIndices(n, cores)
    jobs <- NULL
    cleanup <- function() {
        ## kill children if cleanup is requested
        if (length(jobs) && mc.cleanup) {
            ## first take care of uncollected children
            mccollect(children(jobs), FALSE)
            mckill(children(jobs),
                   if (is.integer(mc.cleanup)) mc.cleanup else 15L)
            mccollect(children(jobs))
        }
        if (length(jobs)) {
            ## just in case there are zombies
            mccollect(children(jobs), FALSE)
        }
    }
    on.exit(cleanup())
    FUN <- match.fun(FUN)
    ## may have more cores than tasks ....
    jobs <- lapply(si,
                   function(i) mcparallel(FUN(v[i], ...),
                                          mc.set.seed = mc.set.seed,
                                          silent = mc.silent))
    res <- mccollect(jobs)
    names(res) <- NULL
    res <- do.call(c, res)
    if (length(res) != n)
        warning("some results may be missing, folded or caused an error")
    res
}
