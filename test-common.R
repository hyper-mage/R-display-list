
Rcmd <- "~/R/R-DL/BUILD/bin/Rscript"

funText <- function(f) {
    bodyText <- deparse(body(f))
    codeText <- paste(bodyText[-c(1, length(bodyText))], collapse=";")
}

doNothing <- function() {
    NULL
}

makeModel <- function(model, filestem, suffix) {
    png <- paste0(filestem, "-", suffix, "-model%02d.png")
    code <- funText(model)
    expr <- paste0('png("', png, '"); dev.control("enable"); ',
                   code)
    cmd <- paste0(Rcmd,  " -e '", expr, "'")
    system(cmd)
}

compareResult <- function(filestem, suffix) {
    # (may involve comparing multiple files)
    replayFiles <- list.files(pattern=paste0(filestem, "-", suffix,
                                  "-replay.*.png"))
    modelFiles <- list.files(pattern=paste0(filestem, "-", suffix,
                                 "-model.*.png"))
    if (length(replayFiles) != length(modelFiles)) {
        stop(paste0("Number of replay files (", length(replayFiles),
                    ") does not match number of model files (",
                    length(modelFiles), ")"))
    }
    for (i in seq_along(modelFiles)) {
        cmpfile <- paste0(filestem, "-diff.png")
        cmpCmd <- paste("compare -metric ae", replayFiles[i], modelFiles[i],
                        cmpfile)
        cmpResult <- system(cmpCmd)
        if (cmpResult != 0) {
            stop(paste0("Files ", replayFiles[i], " and ", modelFiles[i],
                        " do not match"))
        }
    }
}

testCopy <- function(plot, append=doNothing, model, filestem) {
    # Create plot and copy to new device (possibly appending)
    png1 <- paste0(filestem, "-copy-record.png")
    png2 <- paste0(filestem, "-copy-replay%02d.png")
    code1 <- funText(plot)
    code2 <- funText(append)
    expr <- paste0('png("', png1, '"); dev.control("enable"); ',
                   code1,
                   '; dev.copy(png, file="', png2, '"); ',
                   code2)
    cmd <- paste0(Rcmd,  " -e '", expr, "'")
    system(cmd)
    # Produce model answer for copied plot
    makeModel(model, filestem, "copy")
    # Compare copied plot with model answer
    compareResult(filestem, "copy")
}

testReplay <- function(plot, prepend=doNothing, append=doNothing, model,
                       filestem) {
    # Create plot and replay on SAME device (possibly prepending and appending)
    png <- paste0(filestem, "-replay-replay%02d.png")
    code1 <- funText(plot)
    code2 <- funText(prepend)
    code3 <- funText(append)
    expr <- paste0('png("', png, '"); dev.control("enable"); ',
                    code1,
                    '; p <- recordPlot(); ',
                    code2,
                    '; replayPlot(p); ',
                    code3)
    cmd <- paste0(Rcmd,  " -e '", expr, "'")
    system(cmd)
    makeModel(model, filestem, "replay")
    # Compare copied plot with model answer
    compareResult(filestem, "replay")
}

testReload <- function(plot, prepend=doNothing, append=doNothing, model,
                       filestem) {
    # Record plot
    savefile <- paste0(filestem, "-reload-record.rds")
    png1 <- paste0(filestem, "-reload-record.png")
    code1 <- funText(plot)
    expr1 <- paste0('png("', png1, '"); dev.control("enable"); ',
                    code1,
                    '; p <- recordPlot(); saveRDS(p, "', savefile, '")')
    cmd1 <- paste0(Rcmd,  " -e '", expr1, "'")
    system(cmd1)
    # Replay plot (possibly prepend and possibly append new drawing)
    png2 <- paste0(filestem, "-reload-replay%02d.png")
    code2a <- funText(prepend)
    code2b <- funText(append)
    expr2 <- paste0('png("', png2, '"); dev.control("enable"); ',
                    code2a,
                    '; p <- readRDS("', savefile, '"); replayPlot(p); ',
                    code2b)
    cmd2 <- paste0(Rcmd,  " -e '", expr2, "'")
    system(cmd2)
    # Produce model answer for replayed plot
    makeModel(model, filestem, "reload")
    # Compare replayed plot with model answer
    compareResult(filestem, "reload")
}
