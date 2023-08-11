pkg <- commandArgs(TRUE)

pkgNames <- names(installed.packages()[, "Package"])

installed <- pkg %in% pkgNames

nres <- cbind(pkg, installed)

print(nres)

if (any(!installed)) {
    q("no", 1)
}


