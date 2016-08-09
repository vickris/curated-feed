class UsersController < ApplicationController
  before_action :find_user

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:success] = "Interests updated"
      redirect_to root_path
    else
      flash[:alert] = "Interests could not be updated."
      render :edit
    end
  end

  private

    def find_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(tag_ids: [])
    end
end
