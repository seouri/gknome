class Genome < ActiveRecord::Base
  def allele_frequencies
    [allele_frequency_common, allele_frequency_less_common, allele_frequency_rare, allele_frequency_novel]
  end

  def allele_frequencies_percentage
    allele_frequencies.map {|a| a.to_f / unique_variants * 100}
  end

  def allele_frequencies_labels
    ["Common", "Less common", "Rare", "Novel"]
  end

  def gene_components
    [gene_component_3UTR, gene_component_5UTR, gene_component_CDS, gene_component_intergenic, gene_component_intron, gene_component_splice_site]
  end

  def gene_components_percentage
    gene_components.map {|a| a.to_f / unique_variants * 100}
  end

  def gene_components_labels
    ["3UTR", "5UTR", "CDS", "intergenic", "intron", "splice_site"]
  end

  def impacts
    [impact_disrupt, impact_frameshift, impact_in_frame_deletion, impact_in_frame_insertion, impact_missense, impact_misstart, impact_nonsense, impact_nonstop, impact_synonymous]
  end

  def impacts_percentage
    impacts.map {|a| a.to_f / unique_variants * 100}
  end

  def impacts_labels
    ["disrupt", "frameshift", "in_frame_deletion", "in_frame_insertion", "missense", "misstart", "nonsense", "nonstop", "synonymous"]
  end
end
