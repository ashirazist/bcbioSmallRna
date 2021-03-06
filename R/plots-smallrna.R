#' Small RNA-seq quality control plots
#'
#' @rdname plots-smallrna
#' @author Lorena Pantano, Michael Steinbaugh
#' @aliases bcbSmallMicro bcbSmallCluster bcbSmallSizeDist
#' @param bcb [bcbioSmallRnaDataSet].
#' @param color Column in metadata to use to color the bars.
#' @param percentage Whether to plot the percentage or absolute number.
#' @return [ggplot].
#'
#' @description Plot size distribution of small RNA-seq data.
#'
#' @examples
#' library(DEGreport)
#' data(sbcb)
#' bcbSmallSize(sbcb, color = "population")
#' bcbSmallSizeDist(sbcb, color = "population")
#' bcbSmallMicro(sbcb, color = "population")
#' bcbSmallCluster(sbcb, color = "population")
#' data <- bcbSmallPCA(sbcb, minAverage=8)
#' degPCA(data[["counts"]], data[["annotation"]], condition = "population")
#' data <- bcbSmallPCA(sbcb, type = "cluster", minAverage = 8)
#' degPCA(data[["counts"]], data[["annotation"]], condition = "population")
#' @export
bcbSmallSize <- function(bcb, color = NULL) {

    if (is.null(color))
        color <- metadata(bcb)[["interesting_groups"]][1]
    info <- adapter(bcb)[["reads_by_sample"]][,c(1, 3)] %>%
        left_join(metrics(bcb), by = "sample")
    info[[color]] <- as.factor(info[[color]])
    if (!("reads_before_trimming" %in% colnames(info)))
        info[["reads_before_trimming"]] <- info[["total"]]
    info[["pct"]] <- info[["total"]] / info[["reads_before_trimming"]] * 100L
    m <-  metrics(bcb)
    m[["average_sequence"]] <- m[["average_read_length"]] %>%
        gsub(".*-", "", .) %>%
        as.numeric()
    m[[color]] <- as.factor(m[[color]])

    ggdraw() +
        draw_plot(
            ggplot(info,
                   aes_string(x = color, y = "reads_before_trimming",
                              fill = color)) +
                geom_boxplot() +
                geom_jitter() +
                coord_trans(y = "log10") +
                ggtitle("total number of reads") +
                ylab("# reads") +
                theme(legend.position="none",
                    axis.text.x = element_text(
                        angle = 90L, vjust = 0.5, hjust = 1L)),
            0L, 0.63, 1L, 0.35) +
        draw_plot(
            ggplot(info,
                   aes_string(x = color, y = "pct", fill = color)) +
                geom_boxplot() +
                geom_jitter() +
                ggtitle("total % of reads with adapter") +
                ylab("% reads") +
                theme(legend.position="none",
                    axis.text.x = element_text(
                        angle = 90L, vjust = 0.5, hjust = 1L)),
            0L, 0.3, 1L, 0.33) +
        draw_plot(
            ggplot(m,
                   aes_string(x = color, y = "average_sequence")) +
                geom_boxplot() +
                theme(legend.position="none",
                    axis.text.x = element_text(
                        angle = 90L, vjust = 0.5, hjust = 1L)),
            0L, 0L, 1L, 0.3)
}

#' @rdname plots-smallrna
#' @keywords plot
#' @export
bcbSmallSizeDist <- function(bcb, color = NULL, percentage = TRUE){
    if (is.null(color))
        color <- metadata(bcb)[["interesting_groups"]][1]
    size <- adapter(bcb)[["reads_by_pos"]][,1:3] %>%
        left_join(metrics(bcb), by = "sample") %>%
        left_join(adapter(bcb)[["reads_by_sample"]][, c("sample", "total")],
                  by = "sample")
    if (percentage)
        size[["pct"]] <- size[["reads"]] / size[["total"]] * 100L
    else size[["pct"]] <- size[["reads"]] * 1L
    size[["groupby"]] <- as.factor(size[[color]])
    ggdraw() +
        draw_plot(
            ggplot(size,
                   aes_string(x = "size", y = "pct", group = "sample")) +
                geom_line() +
                facet_wrap(~groupby, ncol = 2L) +
                ggtitle("size distribution") +
                ylab("# reads") + xlab("size") +
                theme(
                    axis.text.x = element_text(
                        angle = 90L, vjust = 0.5, hjust = 1L)))
}

#' @rdname plots-smallrna
#' @keywords plot
#' @export
bcbSmallMicro <- function(bcb, color = NULL) {
    if (is.null(color))
        color <- metadata(bcb)[["interesting_groups"]][1]
    m <- metrics(bcb) %>% mutate_if(is.factor, as.character)
    m[[color]] <- as.factor(m[[color]])
    total <- data.frame(sample = colnames(mirna(bcb)),
                        mirtotal = colSums(mirna(bcb)),
                        stringsAsFactors = FALSE) %>%
        left_join(m, by = "sample") %>%
        left_join(adapter(bcb)[["reads_by_sample"]], by ="sample") %>%
        mutate(pct = mirtotal / total * 100L)
    es <- melt(mirna(bcb)) %>%
        mutate_if(is.factor, as.character) %>%
        left_join(m, by = c("X2" = "sample"))
    es[["value"]] <- log2(es[["value"]] + 1L)
    plot_grid(
        ggplot(total, aes_string(x = color,
                                 y = "pct")) +
            geom_boxplot() +
            geom_jitter() +
            ggtitle("Percentage reads being miRNAs") +
            theme(axis.text.x = element_text(
                angle = 90L, hjust = 1L, vjust = 0.5)),
        ggplot(es) +
            geom_density(aes_string(x = "value",
                                    color = color,
                                    group = "X2")) +
            xlab("") +
            ylab("expression") +
            ggtitle("Expression distribution of miRNAs") +
            theme(legend.position="bottom") +
            theme(axis.text.x = element_text(
                angle = 90L, hjust = 1L, vjust = 0.5)),
        nrow = 2L)
}


#' @rdname plots-smallrna
#' @keywords plot
#' @export
bcbSmallCluster <- function(bcb, color = NULL){

    if (is.null(experiments(bcb)[["cluster"]]))
        stop("No cluster data in this analysis.")
    if (is.null(color))
        color <- metadata(bcb)[["interesting_groups"]][1]

    total <- data.frame(sample = colnames(cluster(bcb)),
                        total = colSums(cluster(bcb)))
    class <- experiments(bcb)[["cluster"]] %>% rowData %>%
        .[["priority"]]
    class[class == ""] <- "Intergenic"
    classDF <- bind_cols(bind_cols(cluster(bcb)),
                         ann = class) %>%
        melt() %>%
        set_names(c("ann", "sample", "value")) %>% 
        mutate_if(is.factor, as.character) %>%
        group_by(!!sym("sample"), !!sym("ann")) %>%
        summarise(abundance = sum(value)) %>%
        left_join(., group_by(., !!sym("sample")) %>%
                      summarise(total = sum(abundance))) %>%
        mutate(pct = abundance / total * 100) %>%
        inner_join(colData(bcb)[, c("sample", color), drop = FALSE] %>%
                       as.data.frame(),
                   by = "sample")

    seqs_ma <- experiments(bcb)[["cluster_seqs"]] %>% assay()
    seqs_rows <- experiments(bcb)[["cluster_seqs"]] %>%
        rowData() %>%
        as.data.frame() %>% 
        mutate(size = nchar(as.character(sequence)))
    classDF_seqs <- bind_cols(seqs_rows, seqs_ma) %>% 
        .[,c(3, 8:ncol(.))] %>%
        gather(sample, counts, -priority, -size) %>%
        group_by(priority, size, sample) %>% 
        summarise(counts=sum(counts)) %>% 
        group_by(sample) %>%
        inner_join(colData(bcb)[, c("sample", color), drop = FALSE] %>%
                       as.data.frame(),
                   by = "sample") %>% 
        mutate(pct = counts/sum(counts)*100,
               facet = !!sym(color)) %>% 
        mutate(priority = factor(priority,
                                 levels = c("miRNA", "tRNA", "repeat",
                                            "ncRNA", "gene", 
                                            "other", "non-annotated"))) 

    ggdraw() +
        draw_plot(
            ggplot(classDF_seqs, aes_string("size", "pct", fill = "priority")) +
                geom_bar(stat = "identity", position = "dodge") +
                scale_fill_brewer("type", palette = "Dark2") + 
                facet_wrap(~facet),
            0, 0.5, 1, 0.5) +
        draw_plot(
            melt(cluster(bcb)) %>%
                mutate_if(is.factor, as.character) %>%
                ggplot(aes_string(group = "variable", x = "value")) +
                geom_density() +
                xlab("") +
                ylab("expression") +
                scale_x_log10() +
                ggtitle("Expression distribution of clusters detected") +
                theme(axis.text.x = element_text(
                    angle = 90L, hjust = 1L, vjust = 0.5)),
            0, 0, 0.5, 0.5) +
        draw_plot(
            classDF %>% ggplot(aes_string(x = color, y = "pct", color = "ann")) +
                geom_point(stat = "identity") +
                scale_fill_brewer(palette = "Set1") +
                xlab("type of Small RNA") +
                ylab("% of Expression") +
                theme(axis.text.x = element_text(
                    angle = 90L, hjust = 1L, vjust = 0.5)) +
                facet_wrap(~ann),
            0.5, 0, 0.5, 0.5)
    
}

#' Plot PCA of the different small RNA data
#' @rdname plotsSmallPCA
#' @author Lorena Pantano
#' @keywords plot
#' @description Clustering small RNA samples.
#' @param bcb [bcbioSmallRnaDataSet].
#' @param type Data type to plot: `mirna, cluster, isomir, trna`.
#' @param minAverage Minimun average small RNA expression to be kept. (log2 scale.)
#' @param columns Columns in colData to add to heatmap.
#' @param data Only return data.
#' @param ... Options pass to [DEGreport::degPCA()].
#' @export
bcbSmallPCA <- function(bcb, type = "mirna",
                        minAverage = 5, columns = NULL,
                        data = FALSE, ...) {
    if (is.null(columns))
        columns <- metadata(bcb)[["interesting_groups"]]
    counts <- experiments(bcb)[[type]] %>%
        assays %>% .[["log"]] %>%
        .[rowMeans(.[]) > minAverage, ]
    annotation_col <- experiments(bcb)[[type]] %>%
        colData %>%
        as.data.frame %>%
        .[, columns, drop = FALSE] %>%
        mutate_all(as.factor)
    rownames(annotation_col) <- colnames(counts)
    list(counts = counts, annotation = annotation_col)
}

