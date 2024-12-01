User.create!(
  email: 'test@test.tt',
  password: '12345678',
  username: 'Eldar',
  photo_url: 'https://lh3.googleusercontent.com/ogw/AF2bZygKjbapzeLmtGT_6oQoNtNO4apdp3AxYUVfBzZsoqznVbbm=s64-c-mo'
) if Rails.env.development?