class CreateGenomes < ActiveRecord::Migration
  def self.up
    create_table :genomes do |t|
      t.integer :unique_variants
      t.integer :allele_frequency_common
      t.integer :allele_frequency_less_common
      t.integer :allele_frequency_rare
      t.integer :allele_frequency_novel
      t.integer :gene_component_3UTR
      t.integer :gene_component_5UTR
      t.integer :gene_component_CDS
      t.integer :gene_component_intergenic
      t.integer :gene_component_intron
      t.integer :gene_component_splice_site
      t.integer :impact_disrupt
      t.integer :impact_frameshift
      t.integer :impact_in_frame_deletion
      t.integer :impact_in_frame_insertion
      t.integer :impact_missense
      t.integer :impact_misstart
      t.integer :impact_nonsense
      t.integer :impact_nonstop
      t.integer :impact_synonymous
      t.integer :impact_unknown
      t.integer :varType_del
      t.integer :varType_ins
      t.integer :varType_snp
      t.integer :varType_sub

      t.timestamps
    end
  end

  def self.down
    drop_table :genomes
  end
end
