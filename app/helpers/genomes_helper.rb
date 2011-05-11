module GenomesHelper
  def allele_frequency_graph(genome)
    bar_graph_log("Variants by Allele Frequency", genome.allele_frequencies, ["Common", "Less common", "Rare", "Novel"])
  end

  def allele_frequency_graph2(genome)
    bar_width = 40 
    bar_spacing = 25
    y_max = (genome.allele_frequencies.max * 1.1).to_i
    #y_max = (y_max * 1.1).to_i 
    y_label_max = (y_max.to_f / 10 ** (y_max.to_s.length - 2)).ceil * 10 ** (y_max.to_s.length - 2)
    Gchart.bar(:size => "324x200", :title => "Variants by Allele Frequency", :data => genome.allele_frequencies_percentage, :encoding => 'text', :axis_with_labels => 'x,x,y', :axis_labels => [['Common', 'Less common', 'Rare', 'Novel'], ['(>5%)', '(1-5%)', '(<1%)'], [0, 100]], :bar_colors => '335566', :bar_width_and_spacing => "#{bar_width},#{bar_spacing}", :format => 'image_tag', :custom => "chm=N,666666,0,,11&chma=0,0,0,0", :max_value => 100).html_safe
  end

  def gene_component_graph(genome)
    bar_graph_log("Variants by Gene Components", genome.gene_components_percentage, ["3UTR", "5UTR", "CDS", "splice_site"])
    bar_graph_log("Variants by Gene Components", genome.gene_components, ["3UTR", "5UTR", "CDS", "intergenic", "intron", "splice_site"])
  end

  def impact_graph(genome)
    bar_graph_log("Variants by Impact", genome.impacts, ["disrupt", "frameshift", "in_frame_deletion", "in_frame_insertion", "missense", "misstart", "nonsense", "nonstop", "synonymous"])
    #bar_graph("Variants by Impact", genome.impacts.map{|g| Math.log10(g.to_f / genome.unique_variants * 100)}, ["disrupt", "frameshift", "in_frame_deletion", "in_frame_insertion", "missense", "misstart", "nonsense", "nonstop", "synonymous"])
  end

  def bar_graph(title, data, labels)
    y_max = (data.max * 1.1).to_i
    y_label_max = (y_max.to_f / 10 ** (y_max.to_s.length - 2)).ceil * 10 ** (y_max.to_s.length - 2)
    bar_width = 40
    bar_spacing = 25
    chart_width = (bar_width + bar_spacing) * data.size + 20
    Gchart.bar(:size => "#{chart_width}x200", :title => title, :data => data, :axis_with_labels => "x,y", :axis_labels => [labels, [0.001, 0.01, 0.1, 1, 10, 100]], :bar_width_and_spacing => "#{bar_width},#{bar_spacing}", :bar_colors => "335566", :max_value => 2, :custom => "chds=-3,2", :encoding => "text", :format => "image_tag").html_safe
  end

  def bar_graph_log(title, data, x_labels)
    data = data.map{|d| Math.log10(d).round(2)}
    y_max = data.max.ceil
    y_min = data.min.floor
    y_min = 0
    y_labels = y_min.upto(y_max).map {|y| (10 ** y)}
    bar_width = 40
    bar_spacing = 25
    chart_width = (bar_width + bar_spacing) * data.size + 20
    Gchart.line(:size => "#{600}x250", :title => title, :data => data, :axis_with_labels => "x,y", :axis_labels => [x_labels, y_labels], :axis_range => [[0, 10]], :bar_width_and_spacing => "#{bar_width},#{bar_spacing}", :bar_colors => "335566", :custom => "chds=#{y_min},#{y_max}&chg=#{(100.0 / (data.size - 1)).round(3)},#{(100.0 / (y_labels.size - 1)).round(3)}", :format => "image_tag").html_safe
  end
end
