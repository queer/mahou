use Mahou.Config

%App{
  name: "test",
  image: "nginxdemos/hello",
  scale: 1,
  limits: %Limits{
    cpu: 1,
    ram: 16,
  },
  inner_port: 80,
}
