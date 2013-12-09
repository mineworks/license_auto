// go build
// go run main.go

package main

import (
	"fmt"
	"math/rand"
	"github.com/astaxie/beego"
)

type MainController struct {
	beego.Controller
}

func (this *MainController) Get() {
	this.Ctx.WriteString("hello world")
}

func main() {
	fmt.Println("My favorite number is", rand.Intn(10))
	fmt.Println("Beego is running on http://localhost:8080")
	beego.Router("/", &MainController{})
	beego.Run()
}