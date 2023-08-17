#' Compares fractional snow-covered area (fSCA) images
#'
#' This function compares 2 fSCA images.
#'
#' @param myC first image
#' @param myT second image
#' @param thresh difference threshold (how is this used?)
#' @return stats list of comparison statistics
#' @export
#'
#' 18 Mar 2020 M. J. Brodzik brodzik@colorado.edu 
#' Copyright (C) 2019 Regents of the University of Colorado
#'
SCAcompare <- function(myC,myT,thresh) #remove NA's from myC and myT
{
	
	myC[myC>1] <- 1
	myT[myT>1] <- 1
	myC[myC<thresh] <- 0
	myT[myT<thresh] <- 0
	
	#Cb and Tb, binary
	
	tn <- ((myT==0) & (myC==0))
	fp <- ((myC>0) & (myT==0))
	fn <- ((myC==0) & (myT>0))
	tp <- ((myT>0) & (myC>0))
	
	nnz.tp <- sum(tp!=0)
	nnz.fp <- sum(fp!=0)
	nnz.tn <- sum(tn!=0)
	nnz.fn <- sum(fn!=0)
	
	precision <- nnz.tp / (nnz.tp+nnz.fp)
	recall <- nnz.tp/(nnz.tp+nnz.fn)
	accuracy <- (nnz.tp+nnz.tn)/(nnz.tp+nnz.tn+nnz.fp+nnz.fn)
	specificity <- nnz.tn/(nnz.tn+nnz.fp)
	fstat <- 2*(precision*recall)/(precision+recall)
	
	stats <- list(precision=precision,recall=recall,specificity=specificity,Fstat=fstat,accuracy=accuracy)
	
	diffimage <- myC-myT
	
	#compare the snow fractions (some are 1 or 0)
	
	diffvector <- diffimage[myC>0 | myT>0]	
	denom <- ifelse(length(diffvector)==1,1,length(diffvector)-1)
	stats$meandiff.default <- mean(diffvector)
	stats$meddiff.default <- median(diffvector)
	stats$RMSE.default <- sqrt((norm(diffvector,type="F")^2)/denom)
	
	#compare conditional on true Landsat pixel in (0,100)

	
	diffvector <- diffimage[which( myT != 0 & myT != 100)]	
	denom <- ifelse(length(diffvector)==1,1,length(diffvector)-1)
	stats$meandiff.Tbtwn <- mean(diffvector)
	stats$meddiff.Tbtwn <- median(diffvector)
	stats$RMSE.Tbtwn <- sqrt((norm(diffvector,type="F")^2)/denom)
	
	#compare conditional on true Landsat pixel and downscaled pixel in (0,100)

	
	diffvector <- diffimage[myT != 0 & myT != 100 & myC!= 0 & myC !=100]	
	denom <- ifelse(length(diffvector)==1,1,length(diffvector)-1)
	stats$meandiff.CTbtwn <- mean(diffvector)
	stats$meddiff.CTbtwn <- median(diffvector)
	stats$RMSE.CTbtwn <- sqrt((norm(diffvector,type="F")^2)/denom)
	

	stats
}
