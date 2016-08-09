15.times do
  title = Faker::Lorem.sentence # all options available below
  description = Faker::Lorem.paragraph
  Post.create!(title:  title,
               description: description)
end
