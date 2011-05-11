class CreateResults < ActiveRecord::Migration
  def self.up
    create_table :results do |t|
      t.integer :genome_id, :limit => 2
      t.string :chromosome, :limit => 5
      t.string :source
      t.string :var_type, :limit => 3
      t.integer :var_begin
      t.integer :var_end
      t.string :score
      t.string :var_strand
      t.string :phase
      t.integer :var_id
      t.string :reference_seq
      t.string :variant_seq
      t.string :allele
      t.float :af_dbsnp132_eur
      t.float :af_1000g_eur
      t.float :af_200e_eur
      t.string :impact, :limit => 18
      t.string :variant_seq_index
      t.string :gene_component, :limit => 11
      t.string :transcript_id
      t.string :gene_symbol
      t.string :transcript_position
      t.string :cds_position
      t.string :protein_position
      t.string :reference_codon
      t.string :variant_codon
      t.string :reference_amino_acid
      t.string :variant_amino_acid
      t.float :average_conservation_score
      t.float :portion_with_sequence_repeat
      t.string :sequence_repeat_detail
      t.text :conserved_tfbs
      t.string :mirna
    end
    add_index :results, [:genome_id, :var_id]
    add_index :results, [:genome_id, :var_type, :var_id]
    add_index :results, [:genome_id, :impact, :var_id]
    add_index :results, [:genome_id, :gene_component, :var_id]
    add_index :results, [:genome_id, :impact, :af_dbsnp132_eur, :af_1000g_eur, :af_200e_eur, :gene_symbol], :name => 'index_results_on_genome_id_and_impact_and_af_and_gene_symbol'
  end

  def self.down
    drop_table :results
  end
end