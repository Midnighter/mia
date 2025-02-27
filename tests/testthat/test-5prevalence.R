context("prevalence")

test_that("getPrevalence", {

    data(GlobalPatterns, package="mia")
    expect_error(getPrevalence(GlobalPatterns, detection="test"),
                 "'detection' must be a single numeric value or coercible to one")
    expect_error(getPrevalence(GlobalPatterns, include_lowest="test"),
                 "'include_lowest' must be TRUE or FALSE")
    expect_error(getPrevalence(GlobalPatterns, sort="test"),
                 "'sort' must be TRUE or FALSE")
    expect_error(getPrevalence(GlobalPatterns, as_relative="test"),
                 "'as_relative' must be TRUE or FALSE")
    expect_error(getPrevalence(GlobalPatterns, assay.type="test"),
                 "'assay.type' must be a valid name")
    # Output should be always a frequency between 0 to 1
    pr <- getPrevalence(GlobalPatterns, detection=0.1/100, as_relative=TRUE)
    expect_true(min(pr) >= 0 && max(pr) <= 1)
    pr <- getPrevalence(GlobalPatterns, detection=0.1/100, as_relative=FALSE)
    expect_true(min(pr) >= 0 && max(pr) <= 1)

    # Same prevalences should be returned for as_relative T/F in certain cases.
    pr1 <- getPrevalence(GlobalPatterns, detection=1, include_lowest=TRUE, as_relative=FALSE)
    pr2 <- getPrevalence(GlobalPatterns, detection=0/100, include_lowest=FALSE, as_relative=TRUE)
    expect_true(all(pr1 == pr2))

    # Same prevalences should be returned for as_relative T/F in certain cases.
    pr1 <- getPrevalence(GlobalPatterns, detection=1, include_lowest=TRUE, as_relative=FALSE)
    pr2 <- getPrevalence(GlobalPatterns, detection=0, include_lowest=FALSE, as_relative=FALSE)
    expect_true(all(pr1 == pr2))

    # Different ways to use relative abundance should yield the same output
    pr2 <- getPrevalence(GlobalPatterns, as_relative=TRUE, assay.type = "counts")
    GlobalPatterns <- transformAssay(GlobalPatterns, method="relabundance")
    pr1 <- getPrevalence(GlobalPatterns, as_relative=FALSE, assay.type = "relabundance")
    expect_true(all(pr1 == pr2))

    # Sorting should put the top values first
    pr <- getPrevalence(GlobalPatterns, sort=TRUE, detection = 0.1/100)
    expect_equal(as.vector(which.max(pr)), 1)
    pr <- names(head(getPrevalence(GlobalPatterns, sort=TRUE,  include_lowest = TRUE), 5L))
    actual <- getTop(GlobalPatterns,
                         method="prevalence",
                         top=5,
                         assay.type="counts")
    expect_equal(pr, actual)
    # Test alias
    alias<- getTop(GlobalPatterns,
                       method="prevalence",
                       top=5,
                       assay.type="counts")
    expect_equal(alias, actual)
    # Check that works also when rownames is NULL
    gp_null <- GlobalPatterns
    rownames(gp_null) <- NULL

    pr1 <- unname(getPrevalence(GlobalPatterns, detection=0.004, as_relative=TRUE))
    pr2 <- getPrevalence(gp_null, detection=0.004, as_relative=TRUE)
    expect_equal(pr1, pr2)

    pr1 <- getPrevalence(GlobalPatterns, detection=0.004, as_relative=TRUE, rank = "Family")
    pr2 <- getPrevalence(gp_null, detection=0.004, as_relative=TRUE, rank = "Family")
    expect_equal(pr1, pr2)

    # Check that na.rm works correctly
    tse <- GlobalPatterns
    # Get reference value
    ref <- getPrevalence(tse, assay.type = "counts")
    # Add NA values to matrix
    remove <- c(1, 3, 10)
    assay(tse, "counts")[remove, ] <- NA
    # There should be 3 NA values if na.rm = FALSE. Otherwise there should be 0
    expect_warning(
        res <- getPrevalence(tse, assay.type = "counts", na.rm = FALSE) )
    expect_true( sum(is.na(res)) == 3)
    expect_warning(
        res <- getPrevalence(tse, assay.type = "counts", na.rm = TRUE) )
    expect_true( sum(is.na(res)) == 0)
    # Expect that other than features with NA values are the same as in reference
    expect_warning(
        res <- getPrevalence(tse, assay.type = "counts", na.rm = TRUE))
    res <- res[ !names(res) %in% remove ]
    ref <- ref[ !names(ref) %in% remove ]
    expect_equal( res[ names(ref) ], res[ names(ref) ] )

    # Now test that the number of samples where feature was detected is correct
    tse <- GlobalPatterns
    ref <- getPrevalence(tse, assay.type = "counts")
    # Add NA values to specific feature that has non-zero value
    feature <- rownames(tse)[[7]]
    assay(tse, "counts")[feature, 1] <- NA
    expect_warning(
        res <- getPrevalence(tse, assay.type = "counts", na.rm = TRUE))
    # Get the feature values and check that they have correct number of samples
    res <- res[ feature ]
    ref <- ref[ feature ]
    expect_true(res*ncol(tse) == 2)
    expect_true(ref*ncol(tse) == 3)

    #
    tse <- GlobalPatterns
    rank <- "Genus"
    # Add NA values to matrix
    remove <- c(15, 200)
    assay(tse, "counts")[remove, ] <- NA
    # Check that agglomeration works
    tse_agg <- agglomerateByRank(tse, onRankOnly = FALSE, na.rm = FALSE, rank = rank)
    expect_warning(ref <- getPrevalence(tse_agg, na.rm = FALSE))
    expect_warning(res <- getPrevalence(tse, rank = "Genus", agg.na.rm = FALSE))
    expect_true( all(res == ref, na.rm = TRUE) )
    #
    tse_agg <- agglomerateByRank(
        tse, onRankOnly = FALSE, na.rm = TRUE, rank = rank)
    ref <- getPrevalence(tse_agg, na.rm = TRUE)
    res <- getPrevalence(
        tse, na.rm = TRUE, rank = "Genus", agg.na.rm = TRUE)
    expect_true( all(res == ref, na.rm = TRUE) )
})


test_that("getPrevalent", {

    data(GlobalPatterns, package="mia")
    expect_error(getPrevalent(GlobalPatterns, prevalence="test"),
                 "'prevalence' must be a single numeric value or coercible to one")
    # Results compatible with getPrevalence
    pr1 <- getPrevalent(GlobalPatterns, detection=0.1/100, as_relative=TRUE, sort=TRUE)
    pr2 <- names(getPrevalence(GlobalPatterns, rank = "Kingdom", detection=0.1/100, as_relative=TRUE, sort=TRUE))
    expect_true(all(pr1 == pr2))

    # Same sorting for toptaxa obtained in different ways
    pr1 <- getPrevalent(GlobalPatterns, detection=0.1/100, as_relative=TRUE, sort=TRUE)
    pr2 <- names(getPrevalence(GlobalPatterns, rank = "Kingdom", detection=0.1/100, as_relative=TRUE, sort=TRUE))
    expect_true(all(pr1 == pr2))

    # Retrieved taxa are the same for counts and relative abundances
    pr1 <- getPrevalent(GlobalPatterns, prevalence=0.1/100, as_relative=TRUE)
    pr2 <- getPrevalent(GlobalPatterns, prevalence=0.1/100, as_relative=FALSE)
    expect_true(all(pr1 == pr2))

    # Prevalence and detection threshold at 0 has the same impact on counts and relative abundances
    pr1 <- getPrevalent(GlobalPatterns, detection=0, prevalence=0, as_relative=TRUE)
    pr2 <- getPrevalent(GlobalPatterns, detection=0, prevalence=0, as_relative=FALSE)
    expect_true(all(pr1 == pr2))

    # Check that works also when rownames is NULL
    gp_null <- GlobalPatterns
    rownames(gp_null) <- NULL

    pr1 <- getPrevalent(GlobalPatterns, detection=0.0045, prevalence = 0.25, as_relative=TRUE)
    pr1 <- which(rownames(GlobalPatterns) %in% pr1)
    pr2 <- getPrevalent(gp_null, detection=0.0045, prevalence = 0.25, as_relative=TRUE)
    expect_equal(pr1, pr2)

    # Test alias
    alias <- getPrevalent(gp_null, detection=0.0045, prevalence = 0.25, as_relative=TRUE)
    expect_equal(pr1, alias)

    pr1 <- getPrevalent(GlobalPatterns, detection=0.004, prevalence = 0.1,
                            as_relative=TRUE, rank = "Family")
    pr2 <- getPrevalent(gp_null, detection=0.004, prevalence = 0.1,
                            as_relative=TRUE, rank = "Family")
    expect_equal(pr1, pr2)

})

test_that("getRare", {

    data(GlobalPatterns, package="mia")
    expect_error(getRare(GlobalPatterns, prevalence="test"),
                 "'prevalence' must be a single numeric value or coercible to one")

    ############# Test that output type is correct #############
    expect_type(taxa <- getRare(GlobalPatterns,
                                    detection = 130,
                                    prevalence = 90/100), "character")

    ##### Test that getPrevalent and getRare has all the taxa ####

    # Gets rownames for all the taxa
    all_taxa <- rownames(GlobalPatterns)

    # Gets prevalent taxa
    prevalent_taxa <- getPrevalent(GlobalPatterns,
                                       detection = 0,
                                       prevalence = 90/100,
                                       include_lowest = FALSE)
    # Gets rare taxa
    rare_taxa <- getRare(GlobalPatterns,
                             detection = 0,
                             prevalence = 90/100,
                             include_lowest = FALSE)

    # Concatenates prevalent and rare taxa
    prevalent_and_rare_taxa <- c(prevalent_taxa, rare_taxa)

    # If all the elements are in another vector, vector of TRUEs
    # Opposite --> negative of FALSEs
    # If every element is FALSE, any is FALSE --> opposite --> TRUE
    expect_true( !any( !(all_taxa %in% prevalent_and_rare_taxa) ) &&
                     !any( !( prevalent_and_rare_taxa %in% all_taxa) ) )

    ##### Test that getPrevalent and getRare has all the taxa, ####
    ##### but now with detection limit and with rank #####

    # Check that it works with all the ranks
    ranks <- taxonomyRanks(GlobalPatterns)

    for( rank in ranks ){

        # Agglomerates data by rank
        se <- agglomerateByRank(GlobalPatterns, rank = rank)

        # Gets rownames for all the taxa
        all_taxa <- rownames(se)

        # Gets prevalent taxa
        prevalent_taxa <- getPrevalent(GlobalPatterns,
                                           prevalence = 0.05,
                                           detection = 0.1,
                                           rank = rank,
                                           include_lowest = TRUE, as_relative = TRUE)
        # Gets rare taxa
        rare_taxa <- getRare(GlobalPatterns,
                                 prevalence = 0.05,
                                 detection = 0.1,
                                 rank = rank,
                                 include_lowest = TRUE, as_relative = TRUE)

        # Concatenates prevalent and rare taxa
        prevalent_and_rare_taxa <- c(prevalent_taxa, rare_taxa)

        # If all the elements are in another vector, vector of TRUEs
        # Opposite --> negative of FALSEs
        # If every element is FALSE, any is FALSE --> opposite --> TRUE
        expect_true( !any( !(all_taxa %in% prevalent_and_rare_taxa) ) &&
                         !any( !( prevalent_and_rare_taxa %in% all_taxa) ) )

        # Expect that there are no duplicates
        expect_true(!anyDuplicated(prevalent_taxa))
        expect_true(!anyDuplicated(rare_taxa))

    }

    # Check that works also when rownames is NULL
    gp_null <- GlobalPatterns
    rownames(gp_null) <- NULL

    pr1 <- getRare(GlobalPatterns, detection=0.0045, prevalence = 0.25, as_relative=TRUE)
    pr1 <- which(rownames(GlobalPatterns) %in% pr1)
    pr2 <- getRare(gp_null, detection=0.0045, prevalence = 0.25, as_relative=TRUE)
    expect_equal(pr1, pr2)

    # Test lias
    alias <- getRare(gp_null, detection=0.0045, prevalence = 0.25, as_relative=TRUE)
    expect_equal(pr1, alias)

    pr1 <- getRare(GlobalPatterns, detection=0.004, prevalence = 0.1,
                       as_relative=TRUE, rank = "Family")
    pr2 <- getRare(gp_null, detection=0.004, prevalence = 0.1,
                       as_relative=TRUE, rank = "Family")
    expect_equal(pr1, pr2)

})

test_that("subsetByPrevalent", {
    data(GlobalPatterns, package="mia")
    expect_error(subsetByPrevalent(GlobalPatterns, prevalence="test"),
                 "'prevalence' must be a single numeric value or coercible to one")
    # Expect TSE object
    expect_equal(class(subsetByPrevalent(GlobalPatterns)), class(GlobalPatterns))

    # Results compatible with getPrevalent
    pr1 <- rownames(subsetByPrevalent(
        GlobalPatterns, rank = "Class", detection=0.1/100,
        as_relative=TRUE, sort=TRUE))
    pr2 <- getPrevalent(GlobalPatterns, rank = "Class", detection=0.1/100,
                            as_relative=TRUE, sort=TRUE)
    expect_true(all(pr1 == pr2))

    # Retrieved taxa are the same for counts and relative abundances
    pr1 <- assay(subsetByPrevalent(GlobalPatterns, prevalence=0.1/100, as_relative=TRUE), "counts")
    pr2 <- assay(subsetByPrevalent(GlobalPatterns, prevalence=0.1/100, as_relative=FALSE), "counts")
    expect_true(all(pr1 == pr2))

    # Prevalence and detection threshold at 0 has the same impact on counts and relative abundances
    pr1 <- rownames(subsetByPrevalent(GlobalPatterns, detection=0, prevalence=0, as_relative=TRUE))
    pr2 <- rownames(subsetByPrevalent(GlobalPatterns, detection=0, prevalence=0, as_relative=FALSE))
    expect_true(all(pr1 == pr2))

    # Check that works also when rownames is NULL
    gp_null <- GlobalPatterns
    rownames(gp_null) <- NULL

    pr1 <- subsetByPrevalent(GlobalPatterns, detection=12, prevalence = 0.33)
    pr1 <- unname(assay(pr1, "counts"))
    pr2 <- subsetByPrevalent(gp_null, detection=12, prevalence = 0.33)
    pr2 <- unname(assay(pr2, "counts"))
    expect_equal(pr1, pr2)

    pr1 <- subsetByPrevalent(GlobalPatterns, detection=5, prevalence = 0.33, rank = "Phylum")
    pr1 <- unname(assay(pr1, "counts"))
    pr2 <- subsetByPrevalent(gp_null, detection=5, prevalence = 0.33, rank = "Phylum")
    pr2 <- unname(assay(pr2, "counts"))
    expect_equal(pr1, pr2)

    # Test alias
    alias <- subsetByPrevalent(gp_null, detection=5, prevalence = 0.33, rank = "Phylum")
    alias <- unname(assay(alias, "counts"))
    expect_equal(alias, pr2)

})

test_that("subsetByRare", {
    data(GlobalPatterns, package="mia")
    expect_error(subsetByRare(GlobalPatterns, prevalence="test"),
                 "'prevalence' must be a single numeric value or coercible to one")
    # Expect TSE object
    expect_equal(class(subsetByRare(GlobalPatterns)), class(GlobalPatterns))

    # Results compatible with getRare
    pr1 <- rownames(subsetByRare(
        GlobalPatterns, rank = "Phylum", detection=0.1/100,
        as_relative=TRUE, sort=TRUE))
    pr2 <- getRare(GlobalPatterns, rank = "Phylum", detection=0.1/100,
                       as_relative=TRUE, sort=TRUE)
    expect_true(all(pr1 == pr2))

    # Retrieved taxa are the same for counts and relative abundances
    pr1 <- assay(subsetByRare(GlobalPatterns, prevalence=0.1/100, as_relative=TRUE), "counts")
    pr2 <- assay(subsetByRare(GlobalPatterns, prevalence=0.1/100, as_relative=FALSE), "counts")
    expect_true(all(pr1 == pr2))

    # Prevalence and detection threshold at 0 has the same impact on counts and relative abundances
    pr1 <- rownames(subsetByRare(GlobalPatterns, detection=0, prevalence=0, as_relative=TRUE))
    pr2 <- rownames(subsetByRare(GlobalPatterns, detection=0, prevalence=0, as_relative=FALSE))
    expect_true(all(pr1 == pr2))

    # subsetByRare + subsetByPrevalent should include all the taxa in OTU level
    d <- runif(1, 0.0001, 0.1)
    p <- runif(1, 0.0001, 0.5)
    rare <- rownames(subsetByRare(GlobalPatterns, detection=d, prevalence=p,
                                      as_relative=TRUE))

    prevalent <- rownames(subsetByPrevalent(GlobalPatterns, detection=d, prevalence=p,
                                                as_relative=TRUE))

    all_taxa <- c(rare, prevalent)

    expect_true( all(all_taxa %in% rownames(GlobalPatterns)) )

    # Check that works also when rownames is NULL
    gp_null <- GlobalPatterns
    rownames(gp_null) <- NULL

    pr1 <- subsetByRare(GlobalPatterns, detection=12, prevalence = 0.33)
    pr1 <- unname(assay(pr1, "counts"))
    pr2 <- subsetByRare(gp_null, detection=12, prevalence = 0.33)
    pr2 <- unname(assay(pr2, "counts"))
    expect_equal(pr1, pr2)

    pr1 <- subsetByRare(GlobalPatterns, detection=5, prevalence = 0.33, rank = "Phylum")
    pr1 <- unname(assay(pr1, "counts"))
    pr2 <- subsetByRare(gp_null, detection=5, prevalence = 0.33, rank = "Phylum")
    pr2 <- unname(assay(pr2, "counts"))
    expect_equal(pr1, pr2)

    # Test alias
    alias <- subsetByRare(gp_null, detection=5, prevalence = 0.33, rank = "Phylum")
    alias <- unname(assay(alias, "counts"))
    expect_equal(alias, pr2)

})

test_that("agglomerateByPrevalence", {

    data(GlobalPatterns, package="mia")
    expect_error(agglomerateByPrevalence(GlobalPatterns, other_label=TRUE),
                 "'other_label' must be a single character value")
    actual <- agglomerateByPrevalence(GlobalPatterns, rank = "Kingdom")
    expect_s4_class(actual,class(GlobalPatterns))
    expect_equal(dim(actual),c(2,26))

    actual <- agglomerateByPrevalence(GlobalPatterns,
                                      rank = "Phylum",
                                      detection = 1/100,
                                      prevalence = 50/100,
                                      as_relative = TRUE,
                                      other_label = "test")
    expect_s4_class(actual,class(GlobalPatterns))
    expect_equal(dim(actual),c(6,26))
    expect_equal(rowData(actual)[6,"Phylum"],"test")

    actual <- agglomerateByPrevalence(GlobalPatterns,
                                      rank = NULL,
                                      detection = 0.0001,
                                      prevalence = 50/100,
                                      as_relative = TRUE,
                                      other_label = "test")
    expect_equal(agglomerateByPrevalence(GlobalPatterns,
                                           rank = NULL,
                                           detection = 0.0001,
                                           prevalence = 50/100,
                                           as_relative = TRUE,
                                           other_label = "test"),
                 agglomerateByPrevalence(GlobalPatterns,
                                           rank = NULL,
                                           detection = 0.0001,
                                           prevalence = 50/100,
                                           as_relative = TRUE,
                                           other_label = "test"))
    expect_s4_class(actual,class(GlobalPatterns))
    expect_equal(dim(actual),c(6,26))
    expect_true(all(is.na(rowData(actual)[6,])))
})
