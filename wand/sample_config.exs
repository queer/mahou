use Mahou.Config

%App{
  name: "test",
  image: "nginxdemos/hello",
  limits: %Limits{
    cpu: 1,
    ram: 16,
  },
  inner_port: 80,
}
