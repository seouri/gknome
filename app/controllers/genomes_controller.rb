class GenomesController < ApplicationController
  # GET /genomes
  # GET /genomes.xml
  def index
    @genomes = Genome.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @genomes }
    end
  end

  # GET /genomes/1
  # GET /genomes/1.xml
  def show
    @genome = Genome.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @genome }
    end
  end

  # GET /genomes/new
  # GET /genomes/new.xml
  def new
    @genome = Genome.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @genome }
    end
  end

  # GET /genomes/1/edit
  def edit
    @genome = Genome.find(params[:id])
  end

  # POST /genomes
  # POST /genomes.xml
  def create
    @genome = Genome.new(params[:genome])

    respond_to do |format|
      if @genome.save
        format.html { redirect_to(@genome, :notice => 'Genome was successfully created.') }
        format.xml  { render :xml => @genome, :status => :created, :location => @genome }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @genome.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /genomes/1
  # PUT /genomes/1.xml
  def update
    @genome = Genome.find(params[:id])

    respond_to do |format|
      if @genome.update_attributes(params[:genome])
        format.html { redirect_to(@genome, :notice => 'Genome was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @genome.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /genomes/1
  # DELETE /genomes/1.xml
  def destroy
    @genome = Genome.find(params[:id])
    @genome.destroy

    respond_to do |format|
      format.html { redirect_to(genomes_url) }
      format.xml  { head :ok }
    end
  end
end
