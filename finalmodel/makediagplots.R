# make the diagnostic plots!

library(soap)
source("diagnostics.R")

load("fullmod-Tweedie(1.2).RData") # load the data

# diagnostics - deviance residuals
postscript(file="diag-deviance.eps",width=7,height=5)
diagnostic(it.soap,res=5,resid.type="deviance")
dev.off()

## diagnostics - Pearson residuals
#postscript(file="diag-pearson.eps",width=6,height=6)
#diagnostic(it.soap,res=5,resid.type="pearson")
#dev.off()

