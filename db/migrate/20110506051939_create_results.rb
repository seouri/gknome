class CreateResults < ActiveRecord::Migration
  def self.up
    create_table :results do |t|
      t.integer :genome_id
      t.string :chromosome
      t.string :source
      t.string :var_type
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
      t.string :impact
      t.string :variant_seq_index
      t.string :gene_component
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
    add_index :results, :genome_id
    add_index :results, :var_id
    add_index :results, :var_type
    add_index :results, :impact
  end

  def self.down
    drop_table :results
  end
end