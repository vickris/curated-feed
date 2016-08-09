Many a times upon signing up on a new platform, you are presented with a list of interests to chose so that you only see posts that relate to your interests or rather fine tune your feed. Some of the sites employing this technique are [Quora](https://www.quora.com/), [Medium](https://medium.com/) and [pinterest](https://www.pinterest.com/), just to name a few.  This is a screenshot from quora right after signing up.
![](https://cdn.scotch.io/2083/gDFpcxUKSp2jrjCk5LWa_Screen%20Shot%202016-08-07%20at%2017.29.18.png)


In this tutorial, we are going to implement this feature on a normal blog. In the first part, we will create posts and tag them. Later on, we will add user authentication and let users select their interests. Here is a working demo. The complete code can be found on github link

Let's start by creating a new rails app. I am using rails 4.2 in this tutorial.
`rails new curated-feed`

## The Blog
Now let's create a Posts controller and a post model respectively
```
rails g controller Posts index feed new edit show
rails g model Posts title:string description:text
rake db:migrate
```

I prefer doing this over scaffolding so that I only have code that I need in my controllers. Scaffolding comes with a lot of code.

Let's change our `root_path` to point to the index action of the *posts_controller*

*config/routes.rb*
```ruby
  Rails.application.routes.draw do
    #create routes for performing all CRUD operations on posts
    resources :posts

    #make the homepage the index action of the posts controller
    root 'posts#index'
  end
```

 Let's add code to the controller actions. I will just paste in the code samples
 *app/controllers/posts_controller.rb*
 ```ruby
 class PostsController < ApplicationController
  before_action :find_post, only: [:show, :edit, :update, :destroy]

  def index
    @posts = Post.all
  end

  def feed

  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new post_params
    if @post.save
      flash[:success] = "Post was created successfully"
      redirect_to @post
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @post.update post_params
      flash[:success] = "The post was updated successfully"
      redirect_to @post
    else
      flash.now[:danger] = "Error while submitting post"
      render :edit
    end
  end

  def destroy
    @post.destroy
    redirect_to root_url
  end

  private

    def post_params
      params.require(:post).permit(:title, :description, tag_ids: [])
    end

    def find_post
      @post = Post.find(params[:id])
    end
end

```



Lets create the views. We will use bootstrap since it makes styling quite easy.

*Gemfile*
```
[...]
gem 'bootstrap-sass'
[...]
```
Then run `bundle install`

We need to update our *app/files/css/application.scss* file so that bootstrap styles can take effect.
```css
@import "bootstrap";
@import "bootstrap-sprockets";
```

Let's create our views. I'll just paste in code samples and the folders they are located in.
*app/views/layouts/application.html.erb*
```html
<nav class="navbar navbar-default">
  <div class="container">
    <div class="navbar-header">
      <%= link_to 'Curated-feed', root_path, class: 'navbar-brand' %>
    </div>
    <div id="navbar">
      <ul class="nav navbar-nav pull-right">
        <li><%= link_to 'Sign up', "#" %></li>
      </ul>
    </div>
  </div>
</nav>
<div class="container">
  <% flash.each do |key, value| %>
    <div class="alert alert-<%= key %>">
      <%= value %>
    </div>
  <% end %>
  <%= yield %>
</div>
```

*app/views/posts/_form.html.erb*
```html
<div class="form-group">
  <%= form_for @post do |f| %>
    <div class="form-group">
      <%= f.label :title %>
      <%= f.text_field :title, class: "form-control" %>
    </div>

    <div class="form-group">
      <%= f.label :description %>
      <%= f.text_area :description, class: "form-control" %>
    </div>

    <div class="form-group">
      <%= f.submit class: "btn btn-primary" %>
    </div>
  <% end %>
</div>
```

*app/views/posts/new.html.erb*
```html
<div class="col-md-6 col-md-offset-3">
  <h1>Create a new post</h1>
  <%= render 'form' %>
</div>
```

*app/views/posts/edit.html.erb*
```html
<div class="col-md-6 col-md-offset-3">
  <h1>Create a new post</h1>
  <%= render 'form' %>
</div>
```

*app/views/posts/show.html.erb*
```html
<div class="col-md-8 col-md-offset-2">
  <h1><%= @post.title %></h1>
  <p><%= @post.description %></p>
</div>
```

*app/views/posts/index.html.erb*
```html
<div class="col-md-8 col-md-offset-2">
  <h1>All posts</h1>
  <% @posts.each do |post| %>
    <ul>
      <li>
        <h3><%= post.title %></h3>
        <p><%= post.description %></p>
      </li>
    </ul>
  <% end %>
</div>
```

*app/views/posts/feed.html.erb*
```html
<div class="col-md-8 col-md-offset-2">
  <h1>Feed</h1>

</div>
```

Now that we have our views setup, we can seed our database so that we can see the general layout. 15 posts will work fine.

To seed the database I will take advantage of the faker gem so I can get random titles and post descriptions.
```ruby
[...]
gem 'faker', '~> 1.6', '>= 1.6.6'
[...]
```

We will run `bundle install` to install the gem.

*app/db/seeds.rb*
```ruby
15.times do |n|
  title = Faker::Lorem.sentence # all options available below
  description = Faker::Lorem.paragraph
  Post.create!(title:  title,
               description: description)
end
```

Then do a `rake db:seed` to populate our database with fake data. If you visit `localhost:3000` on your browser you should see the random posts. This was boring though, I am sure you are past the create a blog with rails level. In the next section we will talk about adding tags to posts.

### Tagging posts
With tags and posts you will realise that a tag can have many posts associated with it and a post can have many tags, a many-to-many realationship. To do this, we need a pivot table.

Lets generate the Tag model
```
rails g model Tag title
rake db:migrate
```

Then the pivot model. Lets call it *post_tag*
```
rails g model Post_tag title post:references tag:references
rake db:migrate
```

Then update our models to take note of the relationships.

*app/models/tag.rb*
```ruby
[...]
has_many :post_tags, dependent: :destroy
has_many :posts, through: :post_tags
[...]
```

*app/models/post.rb*
```ruby
[...]
has_many :post_tags, dependent: :destroy
has_many :tags, through: :post_tags
[...]
```

Now that we've declared our relationships, we will add the ability to tag posts when creating or editing them. We have to change the line the specifies the permitted params when creating or updating a post to this and allow *tag_ids* as part of the params.
```ruby
def post_params
  params.require(:post).permit(:title, :desctiption, tag_ids: [])
end
```

Note, we will store the `tag_ids` as an array since a post can be tagged with more than one tag.

We won't be creating a tags controller since we will be creating them through the console in this tutorial. However, we will create a tag partial which will enable us to render tags below posts.

```
mkdir app/views/tags
touch app/views/tags/_tag.html.erb
```

*app/views/tags/tag.html.erb*
```html
<span class="quiet"><small><%= link_to tag.title, "#" %> </small></span>
```

Let's create a few tags through the console. Five will do.

```
rails c
Tag.create!(title: "technology")
Tag.create!(title: "politics")
Tag.create!(title: "science")
Tag.create!(title: "entrepreneurship")
Tag.create!(title: "programming")
```

With tagging posts, we can use checkboxes but in terms of UX this does not give users the best of feelings. We want to do this the same way we tag questions on stack overflow you know. We will require the [chosen-rails](https://github.com/tsechingho/chosen-rails) gem for this. Add this to your gemfile then do a `bundle install`.

*Gemfile*
```ruby
[...]
gem 'compass-rails'
gem 'chosen-rails'
[...]
```

Update the following files to make chosen effective

*app/assets/javascripts/application.js*
```javascript
[...]
//Make sure you require chosen after jquery. In my case I have it after the turbolinks line
//= require chosen-jquery
[...]
```
For those using jquery. There's documentation for the people using prototype on [chosen-rails](https://github.com/tsechingho/chosen-rails) github repo.


*app/assets/css/application.scss*
```css
[...]
*= require chosen
[...]
```

Then in your javascript folder add this coffeescript file

*app/assets/javascripts/tag-select.js.coffee*
```coffee
$ ->
  # enable chosen js
  $('.chosen-select').chosen
    allow_single_deselect: true
    no_results_text: 'No results matched'
    width: '450px'
```

Add this snippet inside your form so that users can choose tag posts
*app/views/posts/_form.html.erb*
```html
<div class="form-group">
    <%= f.collection_select :tag_ids, Tag.order(:title), :id, :title, {}, { multiple: true, class: "chosen-select" } %>
</div>
```


This is how your form should look like now
```html
<div class="form-group">
  <%= form_for @post do |f| %>
    <div class="form-group">
      <%= f.label :title %>
      <%= f.text_field :title, class: "form-control" %>
    </div>

    <div class="form-group">
      <%= f.label :description %>
      <%= f.text_area :description, class: "form-control" %>
    </div>

    <div class="form-group">
      <%= f.collection_select :tag_ids, Tag.order(:title), :id, :title, {}, { multiple: true, class: "chosen-select" } %>
    </div>

    <div class="form-group">
      <%= f.submit class: "btn btn-primary" %>
    </div>
  <% end %>
</div>
```

Try creating a new post. You should be able to add tags and remove tags similar to how you do it on stack overflow. It's possible to let users create tags if they don't exist in the list of available options but that is beyond the scope of this tutorial. We also want to list tags belonging to a post below the post. Update the posts index view to look like this.

*app/views/posts/index*
```html
<div class="col-md-8 col-md-offset-2">
  <h1>All posts</h1>
  <% @posts.each do |post| %>
    <ul>
      <li>
        <h3><%= post.title %></h3>
        <p><%= post.description %></p>
  <% if post.tags.any? %>
          <p>Tags: <%= render post.tags %></p>
        <% end %>
      </li>
    </ul>
  <% end %>
</div>
```




## Modelling Users
Let's allow people to sign up on our platform. We will use [devise](https://github.com/plataformatec/devise) gem for this.

*Gemfile*
```ruby
[...]
gem 'devise', '~> 4.2'
[...]
```
Then do a `bundle install`.

Run the devise generator.
`rails generate devise:install`
Once you run this command you will see a couple of instructions in the console.  Ignore these instructions since we have most of the things set up and won't be sending any emails in this tutorial.

Let's generate the user model
```
rails g devise User
rake db:migrate
```

At this point users are able to sign up and sign in. Let's update the navbar so that users are able to see *sign up*, *sign in* and *logout* links.

*app/views/layouts/application.html.erb*

```html
<nav class="navbar navbar-default">
  <div class="container">
    <div class="navbar-header">
      <%= link_to 'Curated-feed', root_path, class: 'navbar-brand' %>
    </div>
    <div id="navbar">
      <ul class="nav navbar-nav pull-right">
        <% unless user_signed_in? %>
          <li><%= link_to "Sign in", new_user_session_path %></li>
          <li><%= link_to "Sign up", new_user_registration_path %></li>
        <% else %>
          <li><%= link_to "Sign out", destroy_user_session_path, method: :delete %></li>
        <% end %>
      </ul>
    </div>
  </div>
</nav>
<div class="container">
  <% flash.each do |key, value| %>
    <div class="alert alert-<%= key %>">
      <%= value %>
    </div>
  <% end %>
  <%= yield %>
</div>
```

Back to our relationships. A user can subscribe to more than one tag and a tag can have more than one person subscribed to it. A many to many relationship. We will need a pivot table for this.

```
rails g model user_tag user:references tag:references
rake db:migrate
```
Lets update our *Tag* and *User* models. They should now look like this.

*app/models/tag.rb*
```ruby
class Tag < ActiveRecord::Base
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags

  has_many :user_tags, dependent: :destroy
  has_many :users, through: :user_tags
end
```

*app/models/user.rb*
```ruby
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :user_tags, dependent: :destroy
  has_many :tags, through: :user_tags
end
```


Now let's generate a `users controller`, we want *tag_ids* to be part of a user object.

```
rails g controller users edit update
```

Note that the `new` and `create` actions are taken care of by devise. Devise also provides a method to update a user object without providing a password so long as you are editing the attributes inside a `users_controller`. In our case we will pass in `tag_ids` as the params we want to update.

*app/controllers/users_controller.rb*
```ruby
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
      @user = current_user
    end

    def user_params
      params.require(:user).permit(tag_ids: [])
    end

end

```

At this point we can assign `tag_ids` to a user through the console. Let's update our *routes*  file to accomodate the edit and update actions of a user object. We will also create the view for updating user interests and add the link to update interests on our nav.

*config/routes.rb*
```ruby
[...]
resources :users, only: [:edit, :update]
[...]
```

*app/views/users/edit.html.erb*
```html
<div class="col-md-8 col-md-offset-2">
  <h1>Please check your interests</h1>
  <%= form_for (@user) do |f| %>

    <strong>Interests:</strong>
    <%= f.collection_check_boxes :tag_ids, Tag.all, :id, :title do |cb| %>
    <%= cb.label(class: "checkbox-inline input_checkbox") {cb.check_box(class: "checkbox") + cb.text} %>
    <% end %>
    <br><br>

    <div class="form-group">
      <%= f.submit class: "button button_flat button_block" %>
    </div>

  <% end %>
</div>
```

*app/views/layouts/application.html.erb*
```html
[...]
<% unless user_signed_in? %>
  <li><%= link_to "Sign in", new_user_session_path %></li>
  <li><%= link_to "Sign up", new_user_registration_path %></li>
<% else %>
  <li><%= link_to "Update interests", edit_user_path(current_user) %></li>
  <li><%= link_to "Sign out", destroy_user_session_path, method: :delete %></li>
<% end %>
[...]
```

Now if we visit *localhost:3000/users/1/edit* you will see a list of interests with checkboxes next to them. In the edit view we are using the name interests when referring to tags. In most cases however, users are supposed to choose their interests right after signing up before accessing the available content.

Lets make a new controller called *registrations_controller* and add the code to redirect users to the edit view after signing up: `touch app/controllers/registrations_controller.rb`

*app/controllers/registrations_controller.rb*
```ruby
class RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    edit_user_path(current_user)
  end
end
```

Then modify our routes to use the new controller. We will be updating the `devise_for` line to look like this:

*config/routes.rb*
```ruby
[...]
devise_for :users, controllers: { registrations: "registrations" }
[...]
```

So after after signing up, users will be taken to the edit page where they will update their interests before proceeding. We haven't yet updated the code in the `feed` method inside the `posts_controller`. In the meantime, users will just be redirected to the root_path.

Lets update our feed method:
*app/controllers/posts_controller.rb*

```ruby
def feed
  @my_interests = current_user.tag_ids
  @posts = Post.select { |p| (p.tag_ids & @my_interests).any? }
end
```

Lemme explain the code that's inside the feed method. In the first line we are getting all the `tag_ids` belonging to the authenticated user - remember we stored `tag_ids` as an array. In ruby we can look for the intersection between two arrays using the `&` symbol. Let's fire up our console so you can see what I mean.

```ruby
rails c
irb(main):001:0> [1,2,3,4] & [3, 1]
=> [1, 3] #what is returned
irb(main):002:0> [7,3,4,5] & [3, 1]
=> [3]
irb(main):003:0> [2,3,4,5] & [6, 7]
=> []
```

If there's an intersection between two arrays, an array containing the elements common to the two arrays is returned else an empty array is returned. Let's go back to the code inside the `feed` method. Once we get the `tag_ids` belonging to the authenticated user, we can compare these `tag_ids` to the `tag_ids` belonging to a post, if there's an intersection, the post will be selected and passed to the `@posts` variable.

To this point, we are able to load all the posts tagged with either of the interests belonging to the logged in user. Let's update the *feed view*.

*app/views/posts/feed.html.erb*
```html
<div class="col-md-8 col-md-offset-2">
  <h1>Your feed</h1>
  <% @posts.each do |post| %>
    <ul>
      <li>
        <h3><%= post.title %></h3>
        <p><%= post.description %></p>
  <% if post.tags.any? %>
          <p>Tags: <%= render post.tags %></p>
        <% end %>
      </li>
    </ul>
  <% end %>
</div>
```

But still, if we visit our homepage we see all posts ragardless of whether they are tagged with either of the users interests or not. This is because the `root_path` is mapped to `posts#index` . Authenticated users should only see relevant posts, not all posts. Devise comes with a handful of methods and it is possible to define the `root_path` for authenticated users.
In our *routes.rb* add this:

*config/routes.rb*
```ruby
[...]
authenticated :user do
    root 'posts#feed', as: "authenticated_root"
 end

 root 'posts#index'
 [...]
```

So now when we visit *localhost:3000* only posts tagged with either of our interests will show up. Then there's the problem of the authenticated user not having selected any interests. Does this mean that their feed will be empty? Let's revisit the feed method inside *posts_controller* and update it.

```ruby

def feed
  @my_interests = current_user.tag_ids

  #check if the authenticated user has any interests
  if @my_interests.any?
    @posts = Post.select { |p| (p.tag_ids & @my_interests).any? }
  else
    #load all the posts if the authenticated user has not specified any interests
    @posts = Post.all
  end
end

```

## Conclusion
This is a simple approach on how to do this. I wanted to talk about many-to-many relationships and how one check for intersections between different models. You can build on top of this by adding images to tags then displaying the images next to the checkboxes in the *user_edit* view. This is how most sites do it. You can also let users click on the images instead of checkboxes then making ajax calls to update the user object. I mean there are so many ways to make this fancy. I am learning Rails and prefer sharing what I have learnt through blog posts. Hope this tutorial was helpful.
