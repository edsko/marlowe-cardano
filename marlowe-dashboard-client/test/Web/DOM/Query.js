"use strict";

// So that we have a "document"
require("global-jsdom/register");
const { queries } = require("@testing-library/dom");

exports.findAllByAltText = queries.findAllByAltText;
exports.findAllByDisplayValue = queries.findAllByDisplayValue;
exports.findAllByLabelText = queries.findAllByLabelText;
exports.findAllByPlaceholderText = queries.findAllByPlaceholderText;
exports.findAllByRole = queries.findAllByRole;
exports.findAllByTestId = queries.findAllByTestId;
exports.findAllByText = queries.findAllByText;
exports.findAllByTitle = queries.findAllByTitle;
exports.findByAltText = queries.findByAltText;
exports.findByDisplayValue = queries.findByDisplayValue;
exports.findByLabelText = queries.findByLabelText;
exports.findByPlaceholderText = queries.findByPlaceholderText;
exports.findByRole = queries.findByRole;
exports.findByTestId = queries.findByTestId;
exports.findByText = queries.findByText;
exports.findByTitle = queries.findByTitle;
exports.getAllByAltText = queries.getAllByAltText;
exports.getAllByDisplayValue = queries.getAllByDisplayValue;
exports.getAllByLabelText = queries.getAllByLabelText;
exports.getAllByPlaceholderText = queries.getAllByPlaceholderText;
exports.getAllByRole = queries.getAllByRole;
exports.getAllByTestId = queries.getAllByTestId;
exports.getAllByText = queries.getAllByText;
exports.getAllByTitle = queries.getAllByTitle;
exports.getByAltText = queries.getByAltText;
exports.getByDisplayValue = queries.getByDisplayValue;
exports.getByLabelText = queries.getByLabelText;
exports.getByPlaceholderText = queries.getByPlaceholderText;
exports.getByRole = queries.getByRole;
exports.getByTestId = queries.getByTestId;
exports.getByText = queries.getByText;
exports.getByTitle = queries.getByTitle;
exports.queryAllByAltText = queries.queryAllByAltText;
exports.queryAllByDisplayValue = queries.queryAllByDisplayValue;
exports.queryAllByLabelText = queries.queryAllByLabelText;
exports.queryAllByPlaceholderText = queries.queryAllByPlaceholderText;
exports.queryAllByRole = queries.queryAllByRole;
exports.queryAllByTestId = queries.queryAllByTestId;
exports.queryAllByText = queries.queryAllByText;
exports.queryAllByTitle = queries.queryAllByTitle;
exports.queryByAltText = queries.queryByAltText;
exports.queryByDisplayValue = queries.queryByDisplayValue;
exports.queryByLabelText = queries.queryByLabelText;
exports.queryByPlaceholderText = queries.queryByPlaceholderText;
exports.queryByRole = queries.queryByRole;
exports.queryByTestId = queries.queryByTestId;
exports.queryByText = queries.queryByText;
exports.queryByTitle = queries.queryByTitle;
