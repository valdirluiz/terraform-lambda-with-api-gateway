exports.handler = async (event) => {
    console.log("event: ", event);
    return {
        statusCode: 200,
        body: JSON.stringify({ message: "Hello from Lambda!" }),
    };
};