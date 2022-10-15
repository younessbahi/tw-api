$(function () {
    const jsonContainer = $(".js-json-container");
    const data = JSON.parse(jsonContainer.text());

    jsonContainer.jsonViewer(data, {
        collapsed: true,
        withQuotes: false,
        withLinks: false
    });
});

$(function () {
    const jsonContainer2 = $(".js-json-container_a");
    const data = JSON.parse(jsonContainer2.text());

    jsonContainer2.jsonViewer(data, {
        collapsed: true,
        withQuotes: false,
        withLinks: false
    });
});

$(function () {
    const jsonContainer3 = $(".js-json-container_b");
    const data = JSON.parse(jsonContainer3.text());

    jsonContainer3.jsonViewer(data, {
        collapsed: true,
        withQuotes: false,
        withLinks: false
    });
});

$(function () {
    const jsonContainer4 = $(".js-json-container_c");
    const data = JSON.parse(jsonContainer4.text());

    jsonContainer4.jsonViewer(data, {
        collapsed: true,
        withQuotes: false,
        withLinks: false
    });
});