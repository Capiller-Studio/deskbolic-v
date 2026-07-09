# frozen_string_literal: true

module Dashboard
  class LabelsController < DashboardController
    def index
      authorize Label, :index?
      @labels = current_account.labels.all
      @labels = @labels.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    end

    def new
      @label = current_account.labels.new
      authorize @label
    end

    def edit
      @label = current_account.labels.find(params[:id])
      authorize @label
    end

    def create
      @label = Label.new(label_params)
      @label.account_id = current_account.id
      authorize @label

      if @label.save
        redirect_to labels_path, notice: t('dashboard.labels.flash.created', default: "Label created successfully.")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @label = current_account.labels.find(params[:id])
      authorize @label
      
      if @label.update(label_params)
        redirect_to labels_path, notice: t('dashboard.labels.flash.updated', default: "Label updated successfully.")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @label = current_account.labels.find(params[:id])
      authorize @label
      
      @label.destroy

      redirect_to labels_path, notice: t('dashboard.labels.flash.deleted', default: "Label deleted successfully.")
    end

    private

    def label_params
      params.require(:label).permit(:title, :description, :color)
    end
  end
end
