use Mahou.Config

%App{
  name: "test-2",
  image: "nginxdemos/hello",
  limits: %Limits{
    cpu: 1,
    ram: 16,
  },
  inner_port: 80,
  scale: 1,
}
